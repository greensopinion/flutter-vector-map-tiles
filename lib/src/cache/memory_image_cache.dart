import 'dart:collection';

import 'dart:ui';

import '../tile_identity.dart';

class MemoryImageCache {
  int _maxSize;
  final _cache = LinkedHashMap<String, Image>();

  MemoryImageCache(this._maxSize);

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
      _cache[key] = image;
      return image.clone();
    }
  }

  void _applyMaxSize() {
    while (_cache.length > _maxSize) {
      final removed = _cache.remove(_cache.keys.first)!;
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
      '${id.z}.${id.x}.${id.y}.$zoom';
}