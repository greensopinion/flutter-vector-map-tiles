import 'dart:collection';
import 'dart:typed_data';

class MemoryCache {
  final int maxSizeBytes;
  int _currentSizeBytes = 0;
  final LinkedHashMap<String, Uint8List> _cache = LinkedHashMap();

  MemoryCache({required this.maxSizeBytes});

  Uint8List? getItem(String key) {
    var value = _cache.remove(key);
    if (value != null) {
      _cache[key] = value;
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
}
