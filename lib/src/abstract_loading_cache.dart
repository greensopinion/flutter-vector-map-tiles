import 'dart:async';
import 'dart:collection';

import 'dart:math';

abstract class Loader<K, T> {
  Future<T> load(K key);
}

class AbstractLoadingCache<K, T> {
  final _map = LinkedHashMap<K, _CacheBucket<T>>();
  final _fetching = Map<K, Future<T>>();
  int _maxSize;
  final Loader<K, T> loader;
  int accessCount = 0;
  bool _disposed = false;

  AbstractLoadingCache(this.loader, this._maxSize);

  Iterable<K> keys() => _map.keys;

  T? getValue(K key) {
    _checkDisposed();
    final bucket = _map[key];
    if (bucket != null) {
      ++accessCount;
      bucket.accessCount = accessCount;
      return bucket.value;
    }
    return null;
  }

  Future<T> retrieveTile(K key) async {
    _checkDisposed();
    _CacheBucket<T>? bucket = _map[key];
    if (bucket == null) {
      var future = _fetching[key];
      if (future == null) {
        final completer = Completer<T>();
        _fetching[key] = completer.future;
        future = completer.future;
        loader.load(key).then((loaded) {
          if (_disposed) {
            disposeEntry(loaded);
            completer.completeError('disposed');
            return;
          }
          _fetching.remove(key);
          completer.complete(loaded);
          ++accessCount;
          _map[key] = _CacheBucket<T>(loaded, accessCount);
          _constrainCacheSize();
        }).onError((error, stackTrace) {
          _fetching.remove(key);
          completer.completeError(error ?? 'cannot value $key');
        });
      }
      return future;
    } else {
      ++accessCount;
      _map.remove(key);
      bucket.accessCount = accessCount;
      _map[key] = bucket;
    }
    return Future.value(bucket.value);
  }

  void _constrainCacheSize() {
    while (_map.length > _maxSize) {
      _remove(_map.keys.first);
    }
    if (_map.isNotEmpty) {
      var it = _map.entries.iterator;
      final maxAge = 2 * _maxSize;
      while (it.moveNext()) {
        final entry = it.current;
        final age = accessCount - entry.value.accessCount;
        if (age > maxAge) {
          _remove(entry.key);
          it = _map.entries.iterator;
        } else {
          break;
        }
      }
    }
  }

  void dispose() {
    while (_map.isNotEmpty) {
      _remove(_map.keys.first);
    }
    _disposed = true;
  }

  void _remove(K key) {
    final removed = _map.remove(key);
    if (removed != null) {
      disposeEntry(removed.value);
    }
  }

  void releaseMemory() {
    final targetSize = (_map.length / 3).floor();
    while (_map.length > targetSize) {
      _remove(_map.keys.first);
    }
    _maxSize = max(10, (_maxSize * 0.7).floor());
  }

  void disposeEntry(T removed) {}
  void _checkDisposed() {
    if (_disposed) {
      throw 'disposed';
    }
  }
}

class _CacheBucket<T> {
  final T value;
  int accessCount;

  _CacheBucket(this.value, this.accessCount);
}
