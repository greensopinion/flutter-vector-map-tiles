import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../../vector_map_tiles.dart';
import '../executor/executor.dart';
import 'bytes_cache.dart';
import 'cache.dart';
import 'platform_cache_factory.dart';
import 'text_cache.dart';
import 'vector_tile_loading_cache.dart';

class Caches {
  final Executor executor;
  late final AsyncBytesCache _cache;
  late final VectorTileLoadingCache vectorTileCache;
  late final BytesCache memoryVectorTileCache;
  late final TextCache textCache;
  late final List<String> providerSources;

  Caches(
      {required TileProviders providers,
      required this.executor,
      required Theme theme,
      required Duration ttl,
      required int memoryTileCacheMaxSize,
      required int maxSizeInBytes,
      required int maxTextCacheSize}) {
    providerSources = providers.tileProviderBySource.keys.toList();
    _cache = createBytesCache(ttl: ttl, maxSizeInBytes: maxSizeInBytes);
    memoryVectorTileCache = BytesCache(maxSizeBytes: memoryTileCacheMaxSize);
    vectorTileCache = VectorTileLoadingCache(
        _cache, memoryVectorTileCache, providers, executor, theme);
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
        'Text cache hit ratio:              ${textCache.hitRatio.asPct()}% size: ${textCache.size}');
    return cacheStats.join('\n');
  }
}

extension _PctExtension on double {
  double asPct() => (this * 1000).roundToDouble() / 10;
}
