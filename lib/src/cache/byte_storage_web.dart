import 'dart:typed_data';

import 'package:idb_shim/idb_browser.dart';

import 'byte_storage_abstract.dart';

class ByteStorage implements AbstractByteStorage<String, bool> {
  static const int _version = 1;
  static const String _dbName = 'VectorMapCacheDB';
  static const String storeName = 'cache_files_and_metadata';
  static const String _creationDate = 'creation_date';
  static const String _size = 'size';
  static const String _contents = 'contents';
  static const String _keyPath = 'filePath';

  Future<Database> _openDb() async {
    final idbFactory = getIdbFactory();
    if( idbFactory == null ){
      throw Exception('getIdbFactory() failed');
    }
    return idbFactory.open(
      _dbName,
      version: _version,
      onUpgradeNeeded: (e)
      => e.database.createObjectStore(storeName, keyPath: _keyPath),
    );
  }

  @override
  Future<void> write(String path, Uint8List bytes) async {
    final db = await _openDb();
    final now = DateTime.now().millisecondsSinceEpoch;
    final transaction = db.transaction(storeName, idbModeReadWrite);
    final objectStore = transaction.objectStore(storeName);
    objectStore.put({_keyPath: path, _creationDate: now, _size: bytes.length, _contents: bytes});
    await transaction.completed;
  }

  @override
  Future<Uint8List?> read(String path) async {
    final db = await _openDb();
    final txn = db.transaction(storeName, idbModeReadOnly);
    final store = txn.objectStore(storeName);
    final object = await store.getObject(path) as Map?;
    await txn.completed;
    if( object == null ){
      throw Exception('file not found: $path');
    }
    return object['contents'] as Uint8List;
  }

  @override
  Future<void> delete(String path) async {
    final db = await _openDb();
    final txn = db.transaction(storeName, idbModeReadWrite);
    final store = txn.objectStore(storeName);
    await store.delete(path);
    await txn.completed;
  }

  @override
  Future<String?> storageDirectory() async {
    return storeName;
  }

  @override
  Future<bool?> fileOf(String path) async {
    final db = await _openDb();
    final txn = db.transaction(storeName, idbModeReadOnly);
    final store = txn.objectStore(storeName);
    final object = await store.getObject(path);
    await txn.completed;
    return object != null;
  }

  Future<int?> getCreationDate(String path) async {
    final db = await _openDb();
    final transaction = db.transaction(storeName, 'readonly');
    final objectStore = transaction.objectStore(storeName);
    final request = objectStore.getObject(path);

    return request.then((value) {
      if (value != null) {
        return (value as Map)[_creationDate] as int?;
      }
      return null;
    });
  }

  Future<List<String>> getAllKeys() async {
    final db = await _openDb();
    final transaction = db.transaction(storeName, 'readonly');
    final objectStore = transaction.objectStore(storeName);
    final request = objectStore.getAllKeys();

    return request.then((keys) => keys.cast<String>());
  }

  /// Get the file size of a given path.
  Future<int?> getFileSize(String path) async {
    final db = await _openDb();
    final transaction = db.transaction(storeName, 'readonly');
    final objectStore = transaction.objectStore(storeName);
    final request = objectStore.getObject(path);

    return request.then((value) {
      if (value != null) {
        return (value as Map)[_size] as int?;
      }
      return null;
    });
  }
}
