import 'dart:typed_data';

import 'package:http/http.dart';
import 'package:http/retry.dart';

import '../provider_exception.dart';
import '../tile_identity.dart';
import '../vector_tile_provider.dart';

class NetworkVectorTileProvider extends VectorTileProvider {
  @override
  final TileProviderType type;
  final _UrlProvider _urlProvider;
  final Map<String, String>? httpHeaders;

  @override
  final int maximumZoom;

  @override
  final int minimumZoom;

  /// [urlTemplate] the URL template, e.g. `'https://tiles.stadiamaps.com/data/openmaptiles/{z}/{x}/{y}.pbf?api_key=$apiKey'`
  /// [httpHeaders] HTTP headers to include in requests, suitable for passing
  ///  `Authentication` header instead of an `api_key` in the URL template
  /// [maximumZoom] the maximum zoom supported by the tile provider, not to be
  ///  confused with the maximum zoom of the map widget. The map widget will
  ///  automatically use vector tiles from lower zoom levels once the maximum
  ///  supported by this provider is reached.
  NetworkVectorTileProvider(
      {required String urlTemplate,
      this.type = TileProviderType.vector,
      this.httpHeaders,
      this.maximumZoom = 16,
      this.minimumZoom = 1})
      : _urlProvider = _UrlProvider(urlTemplate);

  @override
  Future<Uint8List> provide(TileIdentity tile) async {
    _checkTile(tile);
    final uri = Uri.parse(_urlProvider.url(tile));
    final client = RetryClient(Client());
    try {
      final response = await client.get(uri, headers: httpHeaders);
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      final logSafeUri = uri.toString().split(RegExp(r'\?')).first;
      throw ProviderException(
          message:
              'Cannot retrieve tile: HTTP ${response.statusCode}: $logSafeUri ${response.body}',
          statusCode: response.statusCode,
          retryable: _isRetryable(response.statusCode)
              ? Retryable.retry
              : Retryable.none);
    } on ClientException catch (e) {
      throw ProviderException(message: e.message, retryable: Retryable.retry);
    } finally {
      client.close();
    }
  }

  void _checkTile(TileIdentity tile) {
    if (tile.z > maximumZoom || tile.z < minimumZoom || !tile.isValid()) {
      throw ProviderException(
          message: 'Invalid tile coordinates $tile',
          retryable: Retryable.none,
          statusCode: 400);
    }
  }

  _isRetryable(int statusCode) => statusCode == 503 || statusCode == 408;
}

class _UrlProvider {
  final String urlTemplate;

  _UrlProvider(this.urlTemplate);

  String url(TileIdentity identity) {
    return urlTemplate.replaceAllMapped(RegExp(r'\{(x|y|z)\}'), (match) {
      switch (match.group(1)) {
        case 'x':
          return identity.x.toInt().toString();
        case 'y':
          return identity.y.toInt().toString();
        case 'z':
          return identity.z.toInt().toString();
        default:
          throw Exception(
              'unexpected url template: $urlTemplate - token ${match.group(1)} is not supported');
      }
    });
  }
}
