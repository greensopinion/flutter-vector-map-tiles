import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../vector_map_tiles.dart';
import '../executor/executor.dart';
import '../grid/renderer_pipeline.dart';
import 'byte_storage.dart';
import 'image_tile_loading_cache.dart';
import 'memory_cache.dart';
import 'memory_image_cache.dart';
import 'storage_cache.dart';
import 'text_cache.dart';
import 'tile_image_cache.dart';
import 'vector_tile_loading_cache.dart';

class Caches {
  final Executor executor;
  final ByteStorage _storage = ByteStorage(
      pather: () => getTemporaryDirectory()
          .then((value) => Directory('${value.path}/.vector_map')));
  late final StorageCache _cache;
  late final VectorTileLoadingCache vectorTileCache;
  late final MemoryCache memoryVectorTileCache;
  late final ImageTileLoadingCache imageTileCache;
  late final MemoryImageCache memoryImageCache;
  late final TextCache textCache;
  late final List<String> providerSources;

  Caches(
      {required TileProviders providers,
      required RendererPipeline pipeline,
      required this.executor,
      required Duration ttl,
      required int memoryTileCacheMaxSize,
      required int maxImagesInMemory,
      required int maxSizeInBytes,
      required int maxTextCacheSize}) {
    providerSources = providers.tileProviderBySource.keys.toList();
    _cache = StorageCache(_storage, ttl, maxSizeInBytes);
    memoryVectorTileCache = MemoryCache(maxSizeBytes: memoryTileCacheMaxSize);
    vectorTileCache = VectorTileLoadingCache(
        _cache, memoryVectorTileCache, providers, executor, pipeline.theme);
    imageTileCache = ImageTileLoadingCache(TileImageCache(_cache), pipeline);
    memoryImageCache = MemoryImageCache(maxImagesInMemory);
    textCache = TextCache(maxSize: maxTextCacheSize);
  }

  Future<void> applyConstraints() => _cache.applyConstraints();

  void dispose() {
    memoryImageCache.dispose();
    memoryVectorTileCache.dispose();
  }

  void didHaveMemoryPressure() {
    memoryVectorTileCache.didHaveMemoryPressure();
    memoryImageCache.didHaveMemoryPressure();
  }

  String stats() {
    final cacheStats = <String>[];
    cacheStats
        .add('Storage cache hit ratio:           ${_cache.hitRatio.asPct()}%');
    cacheStats.add(
        'Vector tile cache hit ratio:       ${memoryVectorTileCache.hitRatio.asPct()}% size: ${memoryVectorTileCache.size}');
    cacheStats.add(
        'Image tile cache hit ratio:        ${imageTileCache.hitRatio.asPct()}%');
    cacheStats.add(
        'Image cache hit ratio:             ${memoryImageCache.hitRatio.asPct()}% size: ${memoryImageCache.size}');
    cacheStats.add(
        'Text cache hit ratio:              ${textCache.hitRatio.asPct()}% size: ${textCache.size}');
    return cacheStats.join('\n');
  }
}

extension _PctExtension on double {
  double asPct() => (this * 1000).roundToDouble() / 10;
}
