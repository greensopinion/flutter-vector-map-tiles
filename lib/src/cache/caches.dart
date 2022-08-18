import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../../vector_map_tiles.dart';
import '../executor/executor.dart';
import 'byte_storage.dart';
import 'memory_cache.dart';
import 'storage_cache.dart';
import 'text_cache.dart';
import 'vector_tile_loading_cache.dart';

class Caches {
  final Executor executor;
  final ByteStorage _storage = ByteStorage(
      pather: () => getTemporaryDirectory()
          .then((value) => Directory('${value.path}/.vector_map')));
  late final StorageCache _cache;
  late final VectorTileLoadingCache vectorTileCache;
  late final MemoryCache memoryVectorTileCache;
  late final MemoryTileDataCache memoryTileDataCache;
  late final TextCache textCache;
  late final List<String> providerSources;

  Caches(
      {required TileProviders providers,
      required this.executor,
      required Theme theme,
      required Duration ttl,
      required int memoryTileCacheMaxSize,
      required int memoryTileDataCacheMaxSize,
      required int maxSizeInBytes,
      required int maxTextCacheSize}) {
    providerSources = providers.tileProviderBySource.keys.toList();
    _cache = StorageCache(_storage, ttl, maxSizeInBytes);
    memoryVectorTileCache = MemoryCache(maxSizeBytes: memoryTileCacheMaxSize);
    memoryTileDataCache =
        MemoryTileDataCache(maxSize: memoryTileDataCacheMaxSize);
    vectorTileCache = VectorTileLoadingCache(_cache, memoryVectorTileCache,
        memoryTileDataCache, providers, executor, theme);
    textCache = TextCache(maxSize: maxTextCacheSize);
  }

  Future<void> applyConstraints() => _cache.applyConstraints();

  void dispose() {
    memoryVectorTileCache.dispose();
  }

  void didHaveMemoryPressure() {
    memoryVectorTileCache.didHaveMemoryPressure();
  }

  String stats() {
    final cacheStats = <String>[];
    cacheStats
        .add('Storage cache hit ratio:           ${_cache.hitRatio.asPct()}%');
    cacheStats.add(
        'Vector tile cache hit ratio:       ${memoryVectorTileCache.hitRatio.asPct()}% size: ${memoryVectorTileCache.size}');
    cacheStats.add(
        'Tile data cache hit ratio:         ${memoryTileDataCache.hitRatio.asPct()}% size: ${memoryTileDataCache.size}');
    cacheStats.add(
        'Text cache hit ratio:              ${textCache.hitRatio.asPct()}% size: ${textCache.size}');
    return cacheStats.join('\n');
  }
}

extension _PctExtension on double {
  double asPct() => (this * 1000).roundToDouble() / 10;
}
