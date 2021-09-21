import 'dart:io';
import 'dart:math';

import 'byte_storage.dart';
import 'cache_stats.dart';

class StorageCache with CacheStats {
  final ByteStorage _storage;
  final Duration _ttl;
  final int _maxSizeInBytes;
  int _putCount = 0;

  StorageCache(this._storage, this._ttl, this._maxSizeInBytes);

  Future<List<int>?> retrieve(String key) async {
    final bytes = await _storage.read(key);
    if (bytes == null) {
      cacheMiss();
    } else {
      cacheHit();
    }
    return bytes;
  }

  Future<void> put(String key, List<int> data) async {
    if (++_putCount % 20 == 0) {
      await _applyMaxSize(await _storage.storageDirectory());
    }
    await _storage.write(key, data);
  }

  Future<bool> exists(String key) async {
    final file = await _storage.fileOf(key);
    return file.exists();
  }

  Future<void> applyConstraints() async {
    final directory = await _storage.storageDirectory();
    if (await directory.exists()) {
      try {
        await _applyMaxAge(directory);
        await _applyMaxSize(directory);
      } catch (e) {
        // ignore, race condition directory may have been deleted
      }
    }
  }

  Future<void> _applyMaxAge(Directory directory) async {
    await directory.list().asyncMap((f) => _expireIfExceedsTtl(f)).toList();
  }

  Future<void> _applyMaxSize(Directory directory) async {
    final entries = await directory
        .list()
        .asyncMap((f) => _toEntry(f))
        .where((e) => e.value.type == FileSystemEntityType.file)
        .toList();
    int size = entries.map((e) => e.value.size).reduce((a, b) => a + b);
    final random = Random();
    while (size > _maxSizeInBytes && entries.isNotEmpty) {
      final toRemove = entries.removeAt(random.nextInt(entries.length));
      try {
        await toRemove.key.delete();
        size -= toRemove.value.size;
      } catch (e) {
        // ignore, race condition file was deleted
      }
    }
  }

  Future<void> _expireIfExceedsTtl(FileSystemEntity entity) async {
    final stat = await entity.stat();
    if (stat.type == FileSystemEntityType.file) {
      final exceeds = _exceedsTtl(stat);
      if (exceeds) {
        await entity.delete();
      }
    }
  }

  bool _exceedsTtl(FileStat stat) {
    final now = DateTime.now();
    final age =
        now.millisecondsSinceEpoch - stat.modified.millisecondsSinceEpoch;
    return (age >= _ttl.inMilliseconds);
  }

  Future<MapEntry<FileSystemEntity, FileStat>> _toEntry(
      FileSystemEntity entity) async {
    return MapEntry(entity, await entity.stat());
  }
}
