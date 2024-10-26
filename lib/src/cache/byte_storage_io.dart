import 'dart:io';
import 'dart:typed_data';

import 'byte_storage.dart';

typedef PathFunction = Future<Directory> Function();

class IoByteStorage extends ByteStorage {
  final PathFunction _pather;
  String? _path;

  IoByteStorage._withPath(this._pather);

  IoByteStorage({required PathFunction pather}) : this._withPath(pather);

  Future<String> get _storagePath async {
    String? path = _path;
    if (path == null) {
      final directory = await _pather();
      final exists = await directory.exists();
      if (!exists) {
        await directory.create(recursive: true);
      }
      path = directory.path;
      _path = path;
    }
    return path;
  }

  Future<File> fileOf(String path) async {
    final root = await _storagePath;
    return File("$root/$path");
  }

  Future<Directory> storageDirectory() async {
    final root = await _storagePath;
    return Directory(root);
  }

  @override
  Future<void> write(String path, Uint8List bytes) async {
    final file = await fileOf(path);
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }
    await file.writeAsBytes(bytes);
  }

  @override
  Future<Uint8List?> read(String path) async {
    final file = await fileOf(path);
    if (await file.exists()) {
      return file.readAsBytes();
    }
    return null;
  }

  @override
  Future<void> delete(String path) async {
    final file = await fileOf(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<bool> exists(String key) async {
    final file = await fileOf(key);
    return file.exists();
  }

  @override
  Future<List<ByteStorageEntry>> list() async {
    final directory = await storageDirectory();
    if (await directory.exists()) {
      return await directory
          .list()
          .asyncMap(_toEntry)
          .where((e) => e.value.type == FileSystemEntityType.file)
          .map((f) => ByteStorageEntry(
              path: f.key.path.split(RegExp(r'/|\\')).last,
              size: f.value.size,
              modified: f.value.modified,
              accessed: f.value.accessed))
          .toList();
    }
    return [];
  }

  Future<MapEntry<FileSystemEntity, FileStat>> _toEntry(
      FileSystemEntity entity) async {
    return MapEntry(entity, await entity.stat());
  }
}
