import 'dart:typed_data';

/// Generic interface for storage cache.
abstract class AbstractStorageCache {
  /// Delete a file or entry from the storage.
  Future<void> remove(String key);

  /// Retrieve a file or entry from the storage.
  Future<Uint8List?> retrieve(String key);

  /// Store a file or entry in the storage.
  Future<void> put(String key, Uint8List data);

  /// Check if a file or entry exists in the storage.
  Future<bool> exists(String key);

  /// Apply constraints to the storage.
  Future<void> applyConstraints();
}
