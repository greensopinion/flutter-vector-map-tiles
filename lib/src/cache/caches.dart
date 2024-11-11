import 'package:executor_lib/executor_lib.dart';
import 'package:vector_tile_dem/vector_tile_dem.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../../vector_map_tiles.dart';
import '../provider/caching_vector_tile_provider.dart';
import '../provider/raster_dem_tile_provider.dart';
import 'atlas_image_cache.dart';
import 'byte_storage.dart';
import 'image_loading_cache.dart';
import 'memory_cache.dart';
import 'storage_cache.dart';
import 'text_cache.dart';
import 'vector_tile_loading_cache.dart';

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
  late final ImageLoadingCache imageLoadingCache;

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
      required ByteStorage cacheStorage}) {
    _storage = cacheStorage;
    final vectorProviders = providers.tileProviderBySource.entries.where((e) =>
        e.value.type == TileProviderType.vector ||
        e.value.type == TileProviderType.raster_dem);
    providerSources = vectorProviders.map((e) => e.key).toList();
    storageCache = StorageCache(_storage, ttl, maxSizeInBytes);
    memoryVectorTileCache = MemoryCache(maxSizeBytes: memoryTileCacheMaxSize);
    memoryTileDataCache =
        MemoryTileDataCache(maxSize: memoryTileDataCacheMaxSize);
    final tileProviders = _createTileProviders(theme, vectorProviders);
    vectorTileCache = VectorTileLoadingCache(
        storageCache,
        memoryVectorTileCache,
        memoryTileDataCache,
        tileProviders,
        executor,
        theme);
    textCache = TextCache(maxSize: maxTextCacheSize);
    atlasImageCache = sprites == null
        ? null
        : AtlasImageCache(theme, sprites.atlasProvider, storageCache);
    imageLoadingCache =
        ImageLoadingCache(delegate: storageCache, providers: providers);
  }

  Future<void> applyConstraints() => storageCache.applyConstraints();

  void dispose() {
    memoryVectorTileCache.dispose();
    atlasImageCache?.dispose();
    imageLoadingCache.dispose();
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
    cacheStats.add(
        'Image cache hit ratio:             ${imageLoadingCache.memoryCache.hitRatio.asPct()}% size: ${imageLoadingCache.memoryCache.size}');
    return cacheStats.join('\n');
  }

  TileProviders _createTileProviders(Theme theme,
      Iterable<MapEntry<String, VectorTileProvider>> vectorProviders) {
    final sources = theme.tileSources;
    return TileProviders(Map.fromEntries(vectorProviders
        .where((e) => sources.contains(e.key))
        .map((e) => MapEntry(e.key, _toVector(e.key, e.value)))));
  }

  VectorTileProvider _toVector(String name, VectorTileProvider provider) {
    if (provider.type == TileProviderType.raster_dem) {
      return RasterDemVectorTileProvider(
          executor: executor,
          delegate: CachingVectorTileProvider(
              cache: storageCache,
              cacheKey: (tile) => '$name-dem-${tile.z}-${tile.x}-${tile.y}.png',
              delegate: provider),
          options: ({required int zoom}) {
            if (zoom < 12) {
              return ContourOptions();
            }
            return ContourOptions(minorLevel: 20, majorLevel: 100);
          });
    }
    return provider;
  }
}

extension _PctExtension on double {
  double asPct() => (this * 1000).roundToDouble() / 10;
}
