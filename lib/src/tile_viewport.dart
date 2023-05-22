import 'dart:math';

import 'package:flutter_map/plugin_api.dart';

import '../vector_map_tiles.dart';

class TileViewport {
  final int zoom;
  final Bounds<int> bounds;

  TileViewport(this.zoom, this.bounds);

  /// indicates whether this viewport contains any part of
  /// the given tile
  bool overlaps(TileIdentity tile) {
    if (tile.z == zoom) {
      return bounds.contains(CustomPoint(tile.x, tile.y));
    }
    final zoomDifference = zoom - tile.z;
    final multiplier = pow(2, zoomDifference.abs()).toInt();
    if (zoomDifference > 0) {
      // tile is bigger
      final boundsTopLeft =
          bounds.topLeft.toDoublePoint().multiplyBy(1 / multiplier).floor();
      final boundsBottomRight =
          bounds.bottomRight.toDoublePoint().multiplyBy(1 / multiplier).ceil();
      final tilePoint = CustomPoint(tile.x, tile.y);
      return Bounds(boundsTopLeft, boundsBottomRight)
          .containsPartialBounds(Bounds(tilePoint, tilePoint));
    }
    // tile is smaller
    final tileZoomTopLeft = bounds.topLeft.multiplyBy(multiplier);
    if (tile.x >= tileZoomTopLeft.x && tile.y >= tileZoomTopLeft.y) {
      final tileZoomBottomRight =
          (bounds.bottomRight + const CustomPoint(1, 1)).multiplyBy(multiplier);
      return tile.x < tileZoomBottomRight.x && tile.y < tileZoomBottomRight.y;
    }
    return false;
  }
}
