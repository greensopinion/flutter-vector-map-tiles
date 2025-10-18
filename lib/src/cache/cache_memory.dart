import 'package:stash/stash_api.dart';
import 'package:stash_memory/stash_memory.dart';

import 'abstract_stash_cache.dart';
import 'cache.dart';

class CacheMemory extends AbstractStashCache {
  CacheMemory({required CacheProperties properties})
      : super(
          name: 'memory',
          cacheFactory: () => createStashMemoryCache(properties),
        );
}

Future<BinaryCache> createStashMemoryCache(CacheProperties properties) async {
  final store = await newMemoryCacheStore();
  return store.cache(
    name: 'memory',
    evictionPolicy: const LruEvictionPolicy(),
    maxEntries: properties.memoryCacheMaximumEntries,
    statsEnabled: properties.statsEnabled,
  );
}
