import 'dart:typed_data';

import 'byte_storage.dart';
import 'cache_stats.dart';

class StorageCache with CacheStats {
  final ByteStorage _storage;
  int _putCount = 0;

  StorageCache(this._storage);

  Future<void> remove(String key) async {
    await _storage.delete(key);
  }

  Future<Uint8List?> retrieve(String key) async {
    try {
      final bytes = await _storage.read(key);
      if (bytes == null) {
        cacheMiss();
      } else {
        cacheHit();
      }
      return bytes;
    } catch (e) {
      // ignore, file was likely deleted
      return null;
    }
  }

  Future<void> put(String key, Uint8List data) async {
    if (++_putCount % 20 == 0) {
      await _storage.enforceSize();
    }
    await _storage.write(key, data);
  }

  Future<bool> exists(String key) async {
    return await _storage.exists(key);
  }

  Future<void> applyConstraints() async {
    await _storage.enforceTtl();
    await _storage.enforceSize();
  }
}
