import 'dart:io';
import 'dart:typed_data';

typedef PathFunction = Future<Directory> Function();

class ByteStorage {
  final PathFunction _pather;
  String? _path;

  ByteStorage._withPath(this._pather);

  ByteStorage({required PathFunction pather}) : this._withPath(pather);

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

  Future<void> write(String path, Uint8List bytes) async {
    final file = await fileOf(path);
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }
    await file.writeAsBytes(bytes);
  }

  Future<Uint8List?> read(String path) async {
    final file = await fileOf(path);
    if (await file.exists()) {
      return file.readAsBytes();
    }
    return null;
  }

  Future<void> delete(String path) async {
    final file = await fileOf(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
