import 'dart:typed_data';

abstract class AbstractByteStorage<TDirectory, TFile> {
  Future<void> write(String path, Uint8List bytes);
  Future<Uint8List?> read(String path);
  Future<void> delete(String path);
  Future<TDirectory?> storageDirectory();
  Future<TFile?> fileOf(String path);
}
