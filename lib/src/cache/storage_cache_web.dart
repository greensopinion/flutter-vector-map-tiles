import 'dart:typed_data';
import 'byte_storage_abstract.dart';
import 'byte_storage_web.dart';
import 'cache_stats.dart';
import 'storage_cache_abstract.dart';

class StorageCache with CacheStats implements AbstractStorageCache {
  final AbstractByteStorage<String, bool> _storage;
  final Duration _ttl;
  final int _maxSizeInBytes;
  int _putCount = 0;

  StorageCache(this._storage, this._ttl, this._maxSizeInBytes);

  @override
  Future<void> remove(String key) async {
    await _storage.delete(key);
  }

  @override
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
      return null;
    }
  }

  @override
  Future<void> put(String key, Uint8List data) async {
    if (++_putCount % 20 == 0) {
      await _applyMaxSize();
    }
    await _storage.write(key, data);
  }

  @override
  Future<bool> exists(String key) async {
    final exists = await _storage.fileOf(key);
    return exists ?? false;
  }

  @override
  Future<void> applyConstraints() async {
    await _applyMaxAge();
    await _applyMaxSize();
  }

  /// Apply the maximum age constraint.
  Future<void> _applyMaxAge() async {
    final allKeys = await (_storage as ByteStorage).getAllKeys();
    for (final key in allKeys) {
      final creationDate = await (_storage as ByteStorage).getCreationDate(key);
      if (creationDate != null && _exceedsTtl(creationDate)) {
        await _storage.delete(key);
      }
    }
  }

  /// Apply the maximum size constraint.
  Future<void> _applyMaxSize() async {
    final allKeys = await (_storage as ByteStorage).getAllKeys();
    int totalSize = 0;
    final entries = <String, int>{};

    // Calculating the total size of all entries.
    for (final key in allKeys) {
      final size = await (_storage as ByteStorage).getFileSize(key);
      if (size != null) {
        totalSize += size;
        entries[key] = size;
      }
    }

    // Deleting the least recently used entries until the total size is below the maximum size.
    if (totalSize > _maxSizeInBytes) {
      final sortedEntries = entries.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));

      for (final entry in sortedEntries) {
        await _storage.delete(entry.key);
        totalSize -= entry.value;

        if (totalSize <= _maxSizeInBytes) {
          break;
        }
      }
    }
  }

  bool _exceedsTtl(int creationDate) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final age = now - creationDate;
    return age >= _ttl.inMilliseconds;
  }
}
