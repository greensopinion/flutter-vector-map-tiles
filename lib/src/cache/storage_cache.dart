import 'dart:io';
import 'dart:math';

import 'byte_storage.dart';

class StorageCache {
  final ByteStorage _storage;
  final Duration _ttl;
  final int _maxSizeInBytes;

  StorageCache(this._storage, this._ttl, this._maxSizeInBytes);

  Future<List<int>?> retrieve(String key) {
    return _storage.read(key);
  }

  Future<void> put(String key, List<int> data) {
    return _storage.write(key, data);
  }

  Future<bool> exists(String key) async {
    final file = await _storage.fileOf(key);
    return file.exists();
  }

  Future<void> applyConstraints() async {
    final directory = await _storage.storageDirectory();
    if (await directory.exists()) {
      await directory.list().asyncMap((f) => _expireIfExceedsTtl(f)).toList();
      final entries = await directory
          .list()
          .asyncMap((f) => _toEntry(f))
          .where((e) => e.value.type == FileSystemEntityType.file)
          .toList();
      int size = entries.map((e) => e.value.size).reduce((a, b) => a + b);
      final random = Random();
      while (size > _maxSizeInBytes && entries.isNotEmpty) {
        final toRemove = entries.removeAt(random.nextInt(entries.length));
        size -= toRemove.value.size;
        await toRemove.key.delete();
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
