import 'dart:typed_data';
import 'dart:html';
import 'dart:js' as js;
import 'package:idb_shim/idb.dart';
import 'byte_storage_abstract.dart';

class ByteStorage implements AbstractByteStorage<String, bool> {
  static const String _cacheName = 'vector_map_cache';
  static const String _dbName = 'VectorMapCacheDB';
  static const String _storeName = 'cache_metadata';
  Database? _db;

  ByteStorage() {
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    final request = window.indexedDB!.open(_dbName, version: 1);

    request.onUpgradeNeeded.listen((event) {
      final db = (event.target as Database);
      db.createObjectStore(_storeName, keyPath: 'path');
    });

    request.onSuccess.listen((event) {
      _db = (request.result as Database);
    });

    request.onError.listen((event) {
      print('Error opening IndexedDB: ${request.error}');
    });
  }

  @override
  Future<void> write(String path, Uint8List bytes) async {
    final cache = await js.context.callMethod('caches', ['open', _cacheName]);
    final blob = js.context.callMethod('Blob', [js.JsObject.jsify(bytes)]);
    await cache.callMethod('put', [path, blob]);

    final now = DateTime.now().millisecondsSinceEpoch;
    final transaction = _db!.transaction(_storeName, 'readwrite');
    final objectStore = transaction.objectStore(_storeName);
    objectStore.put({'path': path, 'creation_date': now});
    await transaction.completed;
  }

  @override
  Future<Uint8List?> read(String path) async {
    final cache = await js.context.callMethod('caches', ['match', path]);
    if (cache != null) {
      return cache.callMethod('arrayBuffer');
    }
    return null;
  }

  @override
  Future<void> delete(String path) async {
    final cache = await js.context.callMethod('caches', ['open', _cacheName]);
    await cache.callMethod('delete', [path]);

    final transaction = _db!.transaction(_storeName, 'readwrite');
    final objectStore = transaction.objectStore(_storeName);
    objectStore.delete(path);
    await transaction.completed;
  }

  @override
  Future<String?> storageDirectory() async {
    return _cacheName;
  }

  @override
  Future<bool?> fileOf(String path) async {
    final cache = await js.context.callMethod('caches', ['match', path]);
    return cache != null;
  }

  Future<int?> getCreationDate(String path) async {
    final transaction = _db!.transaction(_storeName, 'readonly');
    final objectStore = transaction.objectStore(_storeName);
    final request = objectStore.getObject(path);

    return request.then((value) {
      if (value != null) {
        return (value as Map)['creation_date'] as int?;
      }
      return null;
    });
  }

  Future<List<String>> getAllKeys() async {
    final transaction = _db!.transaction(_storeName, 'readonly');
    final objectStore = transaction.objectStore(_storeName);
    final request = objectStore.getAllKeys();

    return request.then((keys) => keys.cast<String>());
  }

  /// Get the file size of a given path.
  Future<int?> getFileSize(String path) async {
    final cache = await js.context.callMethod('caches', ['match', path]);
    if (cache != null) {
      final blob = await cache.callMethod('blob');
      return blob.size as int;
    }
    return null;
  }
}
