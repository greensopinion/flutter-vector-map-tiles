import 'dart:io';
import 'dart:typed_data';

import 'package:vector_map_tiles/src/extensions.dart';

import 'byte_storage_mobile.dart';
import 'cache_stats.dart';
import 'storage_cache_abstract.dart';

class StorageCache with CacheStats implements AbstractStorageCache {
final ByteStorage _storage;
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
    // ignore, file was likely deleted
    return null;
  }
}

@override
Future<void> put(String key, Uint8List data) async {
  if (++_putCount % 20 == 0) {
    await _applyMaxSize((await _storage.storageDirectory()) as Directory);
  }
  await _storage.write(key, data);
}

@override
Future<bool> exists(String key) async {
  final file = await _storage.fileOf(key) as File;
  return file.exists();
}

@override
Future<void> applyConstraints() async {
  final directory = await _storage.storageDirectory() as Directory;
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
  int size = entries.isEmpty
      ? 0
      : entries.map((e) => e.value.size).reduce((a, b) => a + b);
  if (size > _maxSizeInBytes) {
    final entriesByAccessed = entries
        .sorted((a, b) => a.value.accessed.compareTo(b.value.accessed));
    for (final entry in entriesByAccessed) {
      try {
        await entry.key.delete();
        size -= entry.value.size;
        if (size <= _maxSizeInBytes) {
          break;
        }
      } catch (e) {
        // ignore, race condition file was deleted
      }
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
