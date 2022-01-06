import 'dart:collection';

import 'cache_stats.dart';

class Sizer<V> {
  int size(V value) => 1;
}

class Copier<V> {
  V? copy(V? value) => value;
  void dispose(V? value) {}
}

class Cache<K, V> with CacheStats {
  int maxSize;
  int _currentSize = 0;
  bool _disposed = false;
  final Sizer _sizer;
  final Copier _copier;

  final LinkedHashMap<K, V> _cache = LinkedHashMap();

  Cache({required this.maxSize, required Sizer sizer, required Copier copier})
      : _sizer = sizer,
        _copier = copier;

  int get size => _currentSize;

  void remove(String key) {
    _copier.dispose(_cache.remove(key));
  }

  V? get(K key) {
    var value = _cache.remove(key);
    if (value != null) {
      _cache[key] = value;
      cacheHit();
    } else {
      cacheMiss();
    }
    return _copier.copy(value);
  }

  void put(K key, V newValue) {
    if (_disposed) {
      return;
    }
    var previousValue = _cache.remove(key);
    if (previousValue != null) {
      _copier.dispose(previousValue);
      _currentSize -= _sizer.size(previousValue);
    }
    _cache[key] = _copier.copy(newValue);
    _currentSize += _sizer.size(newValue);
    _applyConstraints();
  }

  void _applyConstraints() {
    _remove(() => _currentSize > maxSize && _cache.isNotEmpty);
  }

  void didHaveMemoryPressure() {
    maxSize = maxSize ~/ 2;
    clear();
  }

  void dispose() {
    _disposed = true;
    clear();
  }

  void clear() {
    _remove(() => _cache.isNotEmpty);
  }

  void _remove(bool Function() condition) {
    while (condition()) {
      final removed = _cache.remove(_cache.keys.first);
      if (removed != null) {
        _copier.dispose(removed);
        _currentSize -= _sizer.size(removed);
      }
    }
  }
}
