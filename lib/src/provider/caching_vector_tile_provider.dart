import 'dart:typed_data';

import '../../vector_map_tiles.dart';
import '../cache/storage_cache.dart';

class CachingVectorTileProvider extends VectorTileProvider {
  final StorageCache cache;
  final VectorTileProvider delegate;
  final String Function(TileIdentity tile) cacheKey;
  final Map<String, Future<Uint8List>> _byteFuturesByKey = {};

  CachingVectorTileProvider(
      {required this.cache, required this.cacheKey, required this.delegate});

  @override
  int get maximumZoom => delegate.maximumZoom;

  @override
  int get minimumZoom => delegate.minimumZoom;
  @override
  TileOffset get tileOffset => delegate.tileOffset;

  @override
  Future<Uint8List> provide(TileIdentity tile) async {
    final key = cacheKey(tile);
    var bytes = await cache.retrieve(key);
    if (bytes == null) {
      final future = _byteFuturesByKey[key] ?? delegate.provide(tile);
      _byteFuturesByKey[key] = future;
      try {
        bytes = await future;
        await cache.put(key, bytes);
      } finally {
        _byteFuturesByKey.remove(key);
      }
    }
    return bytes;
  }
}
