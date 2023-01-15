import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:http/retry.dart';

import 'cache/memory_cache.dart';
import 'provider_exception.dart';
import 'tile_identity.dart';

abstract class VectorTileProvider {
  /// provides a tile as a `pbf` or `mvt` format
  Future<Uint8List> provide(TileIdentity tile);

  int get maximumZoom;
}

class NetworkVectorTileProvider extends VectorTileProvider {
  final _UrlProvider _urlProvider;
  final Map<String, String>? httpHeaders;
  final int _maximumZoom;

  @override
  int get maximumZoom => _maximumZoom;

  /// [urlTemplate] the URL template, e.g. `'https://tiles.stadiamaps.com/data/openmaptiles/{z}/{x}/{y}.pbf?api_key=$apiKey'`
  /// [httpHeaders] HTTP headers to include in requests, suitable for passing
  ///  `Authentication` header instead of an `api_key` in the URL template
  /// [maximumZoom] the maximum zoom supported by the tile provider, not to be
  ///  confused with the maximum zoom of the map widget. The map widget will
  ///  automatically use vector tiles from lower zoom levels once the maximum
  ///  supported by this provider is reached.
  NetworkVectorTileProvider({required String urlTemplate, this.httpHeaders, int maximumZoom = 16})
      : _urlProvider = _UrlProvider(urlTemplate),
        _maximumZoom = maximumZoom;

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
      throw ProviderException(message: 'Cannot retrieve tile: HTTP ${response.statusCode}: $logSafeUri ${response.body}', statusCode: response.statusCode, retryable: _isRetryable(response.statusCode) ? Retryable.retry : Retryable.none);
    } on ClientException catch (e) {
      throw ProviderException(message: e.message, retryable: Retryable.retry);
    } finally {
      client.close();
    }
  }

  void _checkTile(TileIdentity tile) {
    if (tile.z > _maximumZoom || !tile.isValid()) {
      throw ProviderException(message: 'Invalid tile coordinates $tile', retryable: Retryable.none, statusCode: 400);
    }
  }

  _isRetryable(int statusCode) => statusCode == 503 || statusCode == 408;
}

class MemoryCacheVectorTileProvider extends VectorTileProvider {
  final VectorTileProvider delegate;
  late final MemoryCache _cache;

  @override
  int get maximumZoom => delegate.maximumZoom;

  MemoryCacheVectorTileProvider({required this.delegate, required int maxSizeBytes}) {
    _cache = MemoryCache(maxSizeBytes: maxSizeBytes);
  }

  @override
  Future<Uint8List> provide(TileIdentity tile) async {
    final key = tile.toCacheKey();
    var value = _cache.get(key);
    if (value == null) {
      value = await delegate.provide(tile);
      _cache.put(key, value);
    }
    return value;
  }
}

/// [assetPathTemplate] the asset path template, e.g. `'assets/map_tiles/{z}/{x}/{y}.pbf'`
/// [maximumZoom] the maximum zoom supported by the tile provider, not to be
/// confused with the maximum zoom of the map widget. The map widget will
/// automatically use vector tiles from lower zoom levels once the maximum
/// supported by this provider is reached.
class AssetVectorTileProvider extends VectorTileProvider {
  AssetVectorTileProvider({required this.assetPathTemplate, required this.maximumZoom});
  @override
  final int maximumZoom;
  final String assetPathTemplate;

  @override
  Future<Uint8List> provide(TileIdentity tile) {
    final path = assetPathTemplate.replaceAllMapped(RegExp(r'\{(x|y|z)\}'), (match) {
      switch (match.group(1)) {
        case 'x':
          return tile.x.toString();
        case 'y':
          return tile.y.toString();
        case 'z':
          return tile.z.toString();
        default:
          throw Exception('unexpected url template: $assetPathTemplate - token ${match.group(1)} is not supported');
      }
    });

    return rootBundle.load(path).then((value) => value.buffer.asUint8List());
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
          throw Exception('unexpected url template: $urlTemplate - token ${match.group(1)} is not supported');
      }
    });
  }
}

extension _TileCacheKey on TileIdentity {
  String toCacheKey() => '$z.$x.$y';
}
