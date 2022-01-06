import 'dart:ui';

import '../tile_identity.dart';
import 'cache.dart';

class ImageKey {
  final TileIdentity id;
  final int zoom;
  ImageKey(this.id, this.zoom);

  @override
  operator ==(o) => o is ImageKey && o.id == id && o.zoom == zoom;

  @override
  int get hashCode => hashValues(id, zoom);

  @override
  String toString() => 'ImageKey(id=$id,zoom=$zoom)';
}

class MemoryImageCache extends Cache<ImageKey, Image> {
  MemoryImageCache(int maxSize)
      : super(maxSize: maxSize, copier: _Copier(), sizer: Sizer());
}

class _Copier extends Copier<Image> {
  @override
  Image? copy(Image? value) => value?.clone();
  @override
  void dispose(Image? value) => value?.dispose();
}
