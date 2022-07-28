import 'dart:typed_data';

import 'cache.dart';
import 'memory_cache.dart';

class MemoryAsyncBytesCache extends AsyncBytesCache {
  final MemoryCache<String, Uint8List> _delegate;

  MemoryAsyncBytesCache(this._delegate);

  @override
  Future<void> applyConstraints() async {
    // nothing to do
  }

  @override
  Future<void> clear() async {
    _delegate.clear();
  }

  @override
  Future<bool> exists(String key) async {
    return _delegate.get(key) != null;
  }

  @override
  Future<Uint8List?> get(String key) async {
    return _delegate.get(key);
  }

  @override
  Future<void> put(String key, Uint8List newValue) async {
    _delegate.put(key, newValue);
  }

  @override
  Future<void> remove(String key) async {
    _delegate.remove(key);
  }
}
