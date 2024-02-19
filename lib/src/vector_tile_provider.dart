import 'dart:typed_data';

import 'tile_identity.dart';

enum TileProviderType { vector, raster }

abstract class VectorTileProvider {
  /// provides a tile as a `pbf` or `mvt` format for [type] of [TileProviderType.vector]
  /// or `png` for [TileProviderType.raster]
  Future<Uint8List> provide(TileIdentity tile);

  int get maximumZoom;

  int get minimumZoom;

  TileProviderType get type => TileProviderType.vector;
}
