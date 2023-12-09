import 'dart:math';

import 'package:flutter_map/flutter_map.dart';

import '../vector_map_tiles.dart';

class TileViewport {
  final int zoom;
  final Bounds<int> bounds;

  TileViewport(this.zoom, this.bounds);

  /// indicates whether this viewport contains any part of
  /// the given tile
  bool overlaps(TileIdentity tile) {
    if (tile.z == zoom) {
      return bounds.contains(Point(tile.x, tile.y));
    }
    final zoomDifference = zoom - tile.z;
    final multiplier = pow(2, zoomDifference.abs()).toInt();
    if (zoomDifference > 0) {
      // tile is bigger
      final boundsTopLeft =
          (bounds.topLeft.toDoublePoint() * (1 / multiplier)).floor();
      final boundsBottomRight =
          (bounds.bottomRight.toDoublePoint() * (1 / multiplier)).ceil();
      final tilePoint = Point(tile.x, tile.y);
      return Bounds(boundsTopLeft, boundsBottomRight)
          .containsPartialBounds(Bounds(tilePoint, tilePoint));
    }
    // tile is smaller
    final tileZoomTopLeft = bounds.topLeft * multiplier;
    if (tile.x >= tileZoomTopLeft.x && tile.y >= tileZoomTopLeft.y) {
      final tileZoomBottomRight =
          (bounds.bottomRight + const Point(1, 1)) * multiplier;
      return tile.x < tileZoomBottomRight.x && tile.y < tileZoomBottomRight.y;
    }
    return false;
  }
}
