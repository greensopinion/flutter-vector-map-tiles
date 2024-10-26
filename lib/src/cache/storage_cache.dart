import 'dart:typed_data';

import '../extensions.dart';
import 'byte_storage.dart';
import 'cache_stats.dart';

class StorageCache with CacheStats {
  final ByteStorage _storage;
  final Duration _ttl;
  final int _maxSizeInBytes;
  int _putCount = 0;

  StorageCache(this._storage, this._ttl, this._maxSizeInBytes);

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
      await _applyMaxSize();
    }
    await _storage.write(key, data);
  }

  Future<bool> exists(String key) => _storage.exists(key);

  Future<void> applyConstraints() async {
    try {
      await _applyMaxAge();
      await _applyMaxSize();
    } catch (e) {
      // ignore, race condition directory may have been deleted
    }
  }

  Future<void> _applyMaxAge() async {
    final entries = await _storage.list();
    for (final entry in entries) {
      await _expireIfExceedsTtl(entry);
    }
  }

  Future<void> _applyMaxSize() async {
    final entries = await _storage.list();
    int size = entries.isEmpty
        ? 0
        : entries.map((e) => e.size).reduce((a, b) => a + b);
    if (size > _maxSizeInBytes) {
      final entriesByAccessed =
          entries.sorted((a, b) => a.accessed.compareTo(b.accessed));
      for (final entry in entriesByAccessed) {
        try {
          await _storage.delete(entry.path);
          size -= entry.size;
          if (size <= _maxSizeInBytes) {
            break;
          }
        } catch (e) {
          // ignore, race condition file was deleted
        }
      }
    }
  }

  Future<void> _expireIfExceedsTtl(ByteStorageEntry entity) async {
    final exceeds = _exceedsTtl(entity);
    if (exceeds) {
      await _storage.delete(entity.path);
    }
  }

  bool _exceedsTtl(ByteStorageEntry entry) {
    final now = DateTime.now();
    final age =
        now.millisecondsSinceEpoch - entry.modified.millisecondsSinceEpoch;
    return (age >= _ttl.inMilliseconds);
  }
}
