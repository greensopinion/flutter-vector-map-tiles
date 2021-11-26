import 'dart:collection';

import 'dart:ui';

import '../tile_identity.dart';
import 'cache_stats.dart';

class MemoryImageCache with CacheStats {
  int _maxSize;
  final _cache = LinkedHashMap<String, Image>();
  final _cacheId;

  MemoryImageCache(this._maxSize, this._cacheId);

  void putImage(TileIdentity id, {required double zoom, required Image image}) {
    final key = _toKey(id, zoom);
    _cache.remove(key)?.dispose();
    _cache[key] = image.clone();
    _applyMaxSize();
  }

  Image? getImage(TileIdentity id, {required double zoom}) {
    final key = _toKey(id, zoom);
    final image = _cache.remove(key);
    if (image != null) {
      cacheHit();
      _cache[key] = image;
      return image.clone();
    } else {
      cacheMiss();
    }
  }

  void _applyMaxSize() {
    while (_cache.length > _maxSize) {
      final oldest = _cache.keys.first;
      final removed = _cache.remove(oldest)!;
      removed.dispose();
    }
  }

  void didHaveMemoryPressure() {
    _clear();
    _maxSize = _maxSize ~/ 2;
  }

  void dispose() {
    _clear();
  }

  void _clear() {
    _cache.values.forEach((image) {
      image.dispose();
    });
    _cache.clear();
  }

  String _toKey(TileIdentity id, double zoom) =>
      '${_cacheId}_${id.z}.${id.x}.${id.y}.$zoom';
}
