import 'dart:typed_data';

abstract class ByteStorage {
  Future<void> write(String path, Uint8List bytes);
  Future<Uint8List?> read(String path);
  Future<void> delete(String path);
  Future<bool> exists(String key);
  Future<List<ByteStorageEntry>> list();
}

class ByteStorageEntry {
  final String path;
  final int size;
  final DateTime modified;
  final DateTime accessed;

  ByteStorageEntry(
      {required this.path,
      required this.size,
      required this.modified,
      required this.accessed});
}
