import 'dart:typed_data';

import 'cache_stats.dart';

abstract class AsyncCache<K, V> with CacheStats {
  Future<void> remove(String key);
  Future<V?> get(K key);
  Future<bool> exists(String key);
  Future<void> put(K key, V newValue);
  Future<void> clear();
  Future<void> applyConstraints();
}

typedef AsyncBytesCache = AsyncCache<String, Uint8List>;
