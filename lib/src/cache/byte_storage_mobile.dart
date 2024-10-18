import 'dart:io';
import 'dart:typed_data';
import 'byte_storage_abstract.dart';

typedef PathFunction = Future<Directory> Function();

class ByteStorage implements AbstractByteStorage<Directory, File> {
  final PathFunction _pather;
  String? _path;

  ByteStorage({required PathFunction pather}) : _pather = pather;

  Future<String> get _storagePath async {
    if (_path == null) {
      final directory = await _pather();
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      _path = directory.path;
    }
    return _path!;
  }

  @override
  Future<void> write(String path, Uint8List bytes) async {
    final file = await fileOf(path);
    if (!await file!.parent.exists()) {
      await file.parent.create(recursive: true);
    }
    await file.writeAsBytes(bytes);
  }

  @override
  Future<Uint8List?> read(String path) async {
    final file = await fileOf(path);
    if (await file!.exists()) {
      return file.readAsBytes();
    }
    return null;
  }

  @override
  Future<void> delete(String path) async {
    final file = await fileOf(path);
    if (await file!.exists()) {
      await file.delete();
    }
  }

  @override
  Future<File?> fileOf(String path) async {
    final root = await _storagePath;
    return File("$root/$path");
  }

  @override
  Future<Directory?> storageDirectory() async {
    final root = await _storagePath;
    return Directory(root);
  }
}
