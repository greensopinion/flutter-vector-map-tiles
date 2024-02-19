import 'dart:typed_data';

import '../cache/memory_cache.dart';
import '../tile_identity.dart';
import '../vector_tile_provider.dart';

class MemoryCacheVectorTileProvider extends VectorTileProvider {
  final VectorTileProvider delegate;
  late final MemoryCache _cache;

  @override
  int get maximumZoom => delegate.maximumZoom;

  @override
  int get minimumZoom => delegate.minimumZoom;

  MemoryCacheVectorTileProvider(
      {required this.delegate, required int maxSizeBytes}) {
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

extension _TileCacheKey on TileIdentity {
  String toCacheKey() => '$z.$x.$y';
}
