import 'dart:collection';
import 'dart:typed_data';

import 'package:vector_map_tiles/src/tile_identity.dart';
import 'package:http/http.dart';
import 'package:http/retry.dart';

abstract class VectorTileProvider {
  /// provides a tile as a `pbf` or `mvt` format
  Future<Uint8List> provide(TileIdentity tile);
}

class NetworkVectorTileProvider extends VectorTileProvider {
  final _UrlProvider _urlProvider;
  final Map<String, String>? httpHeaders;
  final RetryClient _retryClient = RetryClient(Client());

  NetworkVectorTileProvider({required String urlTemplate, this.httpHeaders})
      : _urlProvider = _UrlProvider(urlTemplate);

  @override
  Future<Uint8List> provide(TileIdentity tile) async {
    final uri = Uri.parse(_urlProvider.url(tile));
    final response = await _retryClient.get(uri, headers: httpHeaders);
    if (response.statusCode == 200) {
      return response.bodyBytes;
    }
    throw Exception(
        'Cannot retrieve tile: HTTP ${response.statusCode}: ${response.body}');
  }
}

class MemoryCacheVectorTileProvider extends VectorTileProvider {
  final VectorTileProvider delegate;
  final int maxSizeBytes;
  int _currentSizeBytes = 0;
  final LinkedHashMap<TileIdentity, Uint8List> _cache = LinkedHashMap();

  MemoryCacheVectorTileProvider(
      {required this.delegate, required this.maxSizeBytes});

  @override
  Future<Uint8List> provide(TileIdentity tile) async {
    var value = _cache[tile];
    if (value == null) {
      value = await delegate.provide(tile);
      _cache[tile] = value;
      _currentSizeBytes += value.lengthInBytes;
      while (_currentSizeBytes > maxSizeBytes && _cache.isNotEmpty) {
        final removed = _cache.remove(_cache.keys.first);
        _currentSizeBytes -= removed!.lengthInBytes;
      }
    }
    return value;
  }
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
