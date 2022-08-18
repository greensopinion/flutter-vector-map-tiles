import 'dart:typed_data';

import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import 'cache.dart';

class MemoryCache extends Cache<String, Uint8List> {
  MemoryCache({required int maxSizeBytes})
      : super(maxSize: maxSizeBytes, sizer: _Sizer(), copier: Copier());
}

class _Sizer extends Sizer<Uint8List> {
  @override
  int size(Uint8List value) => value.lengthInBytes;
}

class MemoryTileDataCache extends Cache<String, TileData> {
  MemoryTileDataCache({required int maxSize})
      : super(maxSize: maxSize, sizer: Sizer<TileData>(), copier: Copier());
}
