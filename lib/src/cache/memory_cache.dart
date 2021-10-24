import 'dart:collection';
import 'dart:typed_data';

import 'cache_stats.dart';

class MemoryCache with CacheStats {
  int maxSizeBytes;
  int _currentSizeBytes = 0;
  final LinkedHashMap<String, Uint8List> _cache = LinkedHashMap();

  MemoryCache({required this.maxSizeBytes});

  int get sizeInBytes => _currentSizeBytes;

  void removeItem(String key) {
    _cache.remove(key);
  }

  Uint8List? getItem(String key) {
    var value = _cache.remove(key);
    if (value != null) {
      _cache[key] = value;
      cacheHit();
    } else {
      cacheMiss();
    }
    return value;
  }

  void putItem(String key, Uint8List bytes) {
    var value = _cache.remove(key);
    if (value != null) {
      _currentSizeBytes -= value.lengthInBytes;
    }
    _cache[key] = bytes;
    _currentSizeBytes += bytes.lengthInBytes;
    _applyConstraints();
  }

  void _applyConstraints() {
    while (_currentSizeBytes > maxSizeBytes && _cache.isNotEmpty) {
      final removed = _cache.remove(_cache.keys.first);
      _currentSizeBytes -= removed!.lengthInBytes;
    }
  }

  void didHaveMemoryPressure() {
    maxSizeBytes = maxSizeBytes ~/ 2;
    clear();
  }

  void clear() {
    _cache.clear();
    _currentSizeBytes = 0;
  }
}
