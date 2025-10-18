import 'package:stash/stash_api.dart';

import 'abstract_stash_cache.dart';
import 'cache.dart';
import 'cache_io.dart';
import 'cache_memory.dart';

class CacheTiered extends AbstractStashCache {
  CacheTiered({required CacheProperties properties})
      : super(
            name: 'tiered', cacheFactory: () => _createTieredCache(properties));
}

Future<BinaryCache> _createTieredCache(CacheProperties properties) async {
  final memory = await createStashMemoryCache(properties);
  final io = await createStashIoCache(properties);
  return newTieredCache(
    DefaultCacheManager(),
    name: 'tiered',
    memory,
    io,
    statsEnabled: properties.statsEnabled,
  );
}
