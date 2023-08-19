import 'dart:io';

import 'package:executor_lib/executor_lib.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../../vector_map_tiles.dart';
import 'byte_storage.dart';
import 'memory_cache.dart';
import 'storage_cache.dart';
import 'text_cache.dart';
import 'vector_tile_loading_cache.dart';
import 'atlas_image_cache.dart';

class Caches {
  final Executor executor;
  late final ByteStorage _storage;
  late final StorageCache storageCache;
  late final VectorTileLoadingCache vectorTileCache;
  late final MemoryCache memoryVectorTileCache;
  late final MemoryTileDataCache memoryTileDataCache;
  late final TextCache textCache;
  late final List<String> providerSources;
  late final AtlasImageCache? atlasImageCache;

  Caches(
      {required TileProviders providers,
      required this.executor,
      required Theme theme,
      required SpriteStyle? sprites,
      required Duration ttl,
      required int memoryTileCacheMaxSize,
      required int memoryTileDataCacheMaxSize,
      required int maxSizeInBytes,
      required int maxTextCacheSize,
      required Future<Directory> Function() cacheStorage}) {
    _storage = ByteStorage(pather: cacheStorage);
    providerSources = providers.tileProviderBySource.keys.toList();
    storageCache = StorageCache(_storage, ttl, maxSizeInBytes);
    memoryVectorTileCache = MemoryCache(maxSizeBytes: memoryTileCacheMaxSize);
    memoryTileDataCache =
        MemoryTileDataCache(maxSize: memoryTileDataCacheMaxSize);
    vectorTileCache = VectorTileLoadingCache(storageCache,
        memoryVectorTileCache, memoryTileDataCache, providers, executor, theme);
    textCache = TextCache(maxSize: maxTextCacheSize);
    atlasImageCache = sprites == null
        ? null
        : AtlasImageCache(theme, sprites.atlasProvider, storageCache);
  }

  Future<void> applyConstraints() => storageCache.applyConstraints();

  void dispose() {
    memoryVectorTileCache.dispose();
    atlasImageCache?.dispose();
  }

  void didHaveMemoryPressure() {
    memoryVectorTileCache.didHaveMemoryPressure();
  }

  String stats() {
    final cacheStats = <String>[];
    cacheStats.add(
        'Storage cache hit ratio:           ${storageCache.hitRatio.asPct()}%');
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
