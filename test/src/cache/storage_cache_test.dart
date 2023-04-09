import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:vector_map_tiles/src/cache/byte_storage.dart';
import 'package:vector_map_tiles/src/cache/storage_cache.dart';

void main() {
  Directory? folder;
  const encoder = Utf8Encoder();
  const key = 'a-key';
  const anotherKey = 'another-key';
  final data = encoder.convert('a-value');

  setUp(() async {
    final cacheDir = await Directory(
            'build/tmp/storage-cache-${DateTime.now().millisecondsSinceEpoch}')
        .create(recursive: true);
    folder = cacheDir;
  });
  tearDown(() async {
    await folder?.delete(recursive: true);
  });

  StorageCache newCache(
          {Duration ttl = const Duration(minutes: 1),
          int maxSize = 1024 * 10}) =>
      StorageCache(ByteStorage(pather: () async => folder!), ttl, maxSize);

  test('caches an entry', () async {
    final cache = newCache();
    await cache.put(key, data);
    expect(await cache.exists(key), true);
    expect(await cache.retrieve(key), data);
  });

  test('caches an entry persistently', () async {
    final cache = newCache();
    await cache.put(key, data);
    final anotherCache = newCache();
    expect(await anotherCache.exists(key), true);
    expect(await anotherCache.retrieve(key), data);
  });

  test('removes an entry', () async {
    final cache = newCache();
    await cache.put(key, data);
    expect(await cache.exists(key), true);
    await cache.remove(key);
    expect(await cache.exists(key), false);
  });

  test('retrieves a non-existent entry', () async {
    final cache = newCache();
    const nonExistentKey = 'no-such-entry';
    expect(await cache.exists(nonExistentKey), false);
    await cache.remove(nonExistentKey);
    expect(await cache.exists(nonExistentKey), false);
  });

  test('applies constraints when the folder is deleted', () async {
    final cache = newCache();
    await folder?.delete(recursive: true);
    await cache.applyConstraints();
  });
  test('applies constraints leaving data in the cache', () async {
    final cache = newCache();
    await cache.put(key, data);
    await cache.applyConstraints();
    expect(await cache.exists(key), true);
    expect(await cache.retrieve(key), data);
  });
  test('applies constraints removing entries when ttl expires', () async {
    const ttl = Duration(seconds: 1);
    final cache = newCache(ttl: ttl);
    await cache.put(key, data);
    sleep(ttl + const Duration(milliseconds: 2));
    await cache.put(anotherKey, data);
    await cache.applyConstraints();
    expect(await cache.exists(key), false);
    expect(await cache.exists(anotherKey), true);
    expect(await cache.retrieve(anotherKey), data);
  });
  test('applies constraints removing oldest entries when size is exceeded',
      () async {
    final cache = newCache(maxSize: data.length * 10);
    final keys = List.generate(10, (index) => 'key-$index');
    for (final key in keys) {
      await cache.put(key, data);
    }
    sleep(const Duration(seconds: 1));
    for (var x = 0; x < (keys.length - 1); ++x) {
      await cache.retrieve(keys[x]);
      expect(await cache.exists(keys[x]), true);
    }
    await cache.put(anotherKey, data);
    await cache.applyConstraints();
    for (var x = 0; x < (keys.length - 1); ++x) {
      expect(await cache.exists(keys[x]), true);
    }
    expect(await cache.exists(keys[keys.length - 1]), false);
    expect(await cache.exists(anotherKey), true);
  });
}
