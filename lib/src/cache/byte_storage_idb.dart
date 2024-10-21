import 'dart:typed_data';

import 'package:idb_shim/idb_browser.dart';

import 'byte_storage.dart';

class IdbByteStorage extends ByteStorage {
  static const _databaseName = 'vector_map_tiles';
  static const _version = 1;
  static const _storeName = 'ByteStorage';
  static const _bytes = 'bytes';
  static const _size = 'size';
  static const _modified = 'modified';

  int _referenceCount = 0;
  Future<Database>? _database;

  Future<Database> _openDatabase() {
    var database = _database;
    if (database == null) {
      final factory = getIdbFactory();
      if (factory == null) {
        throw 'Unsupported';
      }
      database = factory.open(_databaseName,
          version: _version,
          onUpgradeNeeded: (e) => e.database.createObjectStore(_storeName));
      _database = database;
    }
    return database;
  }

  Future<T> _withDb<T>(Future<T> Function(ObjectStore) command,
      {required _Mode mode}) async {
    Database? database;
    ++_referenceCount;
    try {
      database = await _openDatabase();
      final tranasaction = database.transaction(
          _storeName, mode == _Mode.read ? idbModeReadOnly : idbModeReadWrite);
      final store = tranasaction.objectStore(_storeName);
      final v = command(store);
      await tranasaction.completed;
      return v;
    } finally {
      if (--_referenceCount == 0) {
        _database = null;
        database?.close();
      }
    }
  }

  @override
  Future<void> delete(String path) async {
    await _withDb((s) async => await s.delete(path), mode: _Mode.write);
  }

  @override
  Future<bool> exists(String key) =>
      _withDb((s) async => (await s.getAllKeys()).contains(key),
          mode: _Mode.read);

  @override
  Future<List<ByteStorageEntry>> list() async {
    return await _withDb((s) async {
      final keys = await s.getAllKeys();
      final entries = <ByteStorageEntry>[];
      for (final key in keys) {
        final object = await s.getObject(key);
        if (object is Map) {
          final modified =
              DateTime.fromMillisecondsSinceEpoch(object[_modified] as int);
          entries.add(ByteStorageEntry(
              path: key.toString(),
              size: object[_size],
              modified: modified,
              accessed: modified));
        }
      }
      return entries;
    }, mode: _Mode.read);
  }

  @override
  Future<Uint8List?> read(String path) async {
    return await _withDb((s) async {
      final object = await s.getObject(path);
      if (object is Map) {
        return object[_bytes] as Uint8List;
      }
      return null;
    }, mode: _Mode.read);
  }

  @override
  Future<void> write(String path, Uint8List bytes) async {
    await _withDb((s) async {
      await s.put({
        _bytes: bytes,
        _modified: DateTime.now().millisecondsSinceEpoch,
        _size: bytes.length
      }, path);
      return null;
    }, mode: _Mode.write);
  }
}

enum _Mode { write, read }
