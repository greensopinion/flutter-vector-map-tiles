import 'dart:io';
import 'dart:typed_data';
import 'dart:collection';

abstract class ByteStorage {
  Future<bool> exists(String path);
  Future<void> write(String path, Uint8List bytes);
  Future<Uint8List?> read(String path);
  Future<void> delete(String path);

  Future<void> enforceSize();
  Future<void> enforceTtl();
}

typedef PathFunction = Future<Directory> Function();

class FileSystemByteStorage implements ByteStorage {
  final PathFunction _pather;
  final int _maxSizeInBytes;
  final Duration _ttl;

  String? _path;
  DateTime? _oldestValid;

  FileSystemByteStorage({
    required PathFunction pather,
    required int maxSizeInBytes,
    required Duration ttl,
  })  : _pather = pather,
        _maxSizeInBytes = maxSizeInBytes,
        _ttl = ttl;

  Future<String> get _storagePath async {
    String path = _path ??= await () async {
      final directory = await _pather();
      final exists = await directory.exists();
      if (!exists) {
        await directory.create(recursive: true);
      }
      return directory.path;
    }();
    return path;
  }

  @override
  Future<bool> exists(String path) async {
    final root = await _storagePath;
    return await File("$root/$path").exists();
  }

  @override
  Future<void> write(String path, Uint8List bytes) async {
    final file = await _fileOf(path);
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }
    await file.writeAsBytes(bytes);
  }

  @override
  Future<Uint8List?> read(String path) async {
    final file = await _fileOf(path);
    if (await file.exists()) {
      return file.readAsBytes();
    }
    return null;
  }

  @override
  Future<void> delete(String path) async {
    final file = await _fileOf(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<void> enforceSize() async {
    final directory = Directory(await _storagePath);
    final entries = await directory
        .list()
        .asyncMap((f) async => MapEntry(f, await f.stat()))
        .where((e) => e.value.type == FileSystemEntityType.file)
        .toList();
    int size = entries.isEmpty
        ? 0
        : entries.map((e) => e.value.size).reduce((a, b) => a + b);
    if (size <= _maxSizeInBytes) {
      return;
    }

    entries.sort((a, b) => a.value.accessed.compareTo(b.value.accessed));
    for (final entry in entries) {
      try {
        await entry.key.delete();
        size -= entry.value.size;
        if (size <= _maxSizeInBytes) {
          return;
        }
      } catch (e) {
        // ignore, race condition file was deleted
      }
    }
  }

  @override
  Future<void> enforceTtl() async {
    final now = DateTime.now();
    if (_oldestValid != null && now.difference(_oldestValid!) <= _ttl) {
      return;
    }

    final root = Directory(await _storagePath);
    final deletions = <Future>[];
    await for (final f in root.list()) {
      deletions.add(_expireIfExceedsTtl(now, f));
    }
    await Future.wait(deletions);
  }

  Future<void> _expireIfExceedsTtl(
    DateTime now,
    FileSystemEntity entity,
  ) async {
    final stat = await entity.stat();
    if (stat.type != FileSystemEntityType.file) {
      return;
    }

    final expired = now.difference(stat.modified) > _ttl;
    if (expired) {
      await entity.delete();
    } else if (_oldestValid == null || stat.modified.isBefore(_oldestValid!)) {
      _oldestValid = stat.modified;
    }
  }

  Future<File> _fileOf(String path) async {
    final root = await _storagePath;
    return File("$root/$path");
  }
}

class _CacheEntry {
  final Uint8List _data;
  final DateTime created;
  late DateTime accessed;

  _CacheEntry(this._data) : created = DateTime.now() {
    accessed = created;
  }

  Uint8List get data {
    accessed = DateTime.now();
    return _data;
  }
}

class InMemoryByteStorage extends ByteStorage {
  final HashMap<String, _CacheEntry> _store;
  final int _maxSizeInBytes;
  final Duration _ttl;

  InMemoryByteStorage({
    required int maxSizeInBytes,
    required Duration ttl,
  })  : _store = HashMap<String, _CacheEntry>(),
        _maxSizeInBytes = maxSizeInBytes,
        _ttl = ttl;

  @override
  Future<bool> exists(String path) async {
    return _store.containsKey(path);
  }

  @override
  Future<void> write(String path, Uint8List bytes) async {
    _store[path] = _CacheEntry(bytes);
  }

  @override
  Future<Uint8List?> read(String path) async {
    final entry = _store[path];
    if (entry == null) {
      return null;
    }
    return entry.data;
  }

  @override
  Future<bool> delete(String path) async {
    return _store.remove(path) != null;
  }

  @override
  Future<void> enforceSize() async {
    int size = 0;
    final entries = _store.entries.map((entry) {
      final len = entry.value._data.length;
      size += len;
      return (entry.key, entry.value.accessed, len);
    }).toList(growable: false);

    if (size <= _maxSizeInBytes) {
      return;
    }

    entries.sort((a, b) => a.$2.compareTo(b.$2));
    for (final entry in entries) {
      _store.remove(entry.$1);
      size -= entry.$3;

      if (size <= _maxSizeInBytes) {
        return;
      }
    }
  }

  @override
  Future<void> enforceTtl() async {
    final now = DateTime.now();
    _store.removeWhere((_, entry) => now.difference(entry.created) > _ttl);
  }
}
