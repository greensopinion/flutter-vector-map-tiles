import 'dart:math';
import 'dart:ui';

import '../vector_map_tiles.dart';

class TileViewport {
  final int zoom;
  final Rect bounds;

  TileViewport(this.zoom, this.bounds);

  /// indicates whether this viewport contains any part of
  /// the given tile
  bool overlaps(TileIdentity tile) {
    if (tile.z == zoom) {
      return bounds.contains(Offset(tile.x.toDouble(), tile.y.toDouble()));
    }

    final zoomDifference = zoom - tile.z;
    final multiplier = pow(2, zoomDifference.abs()).toDouble();

    if (zoomDifference > 0) {
      final boundsTopLeft = Offset(
        (bounds.left / multiplier).floorToDouble(),
        (bounds.top / multiplier).floorToDouble(),
      );
      final boundsBottomRight = Offset(
        (bounds.right / multiplier).ceilToDouble(),
        (bounds.bottom / multiplier).ceilToDouble(),
      );

      final tilePoint = Offset(tile.x.toDouble(), tile.y.toDouble());
      final tileRect = Rect.fromLTWH(tilePoint.dx, tilePoint.dy, 1, 1);
      final scaledBounds = Rect.fromLTRB(
        boundsTopLeft.dx,
        boundsTopLeft.dy,
        boundsBottomRight.dx,
        boundsBottomRight.dy,
      );
      return scaledBounds.overlaps(tileRect);
    }
    final scaledBoundsTopLeft = Offset(
      bounds.left * multiplier,
      bounds.top * multiplier,
    );

    final scaledBoundsBottomRight = Offset(
      bounds.right * multiplier,
      bounds.bottom * multiplier,
    );

    return tile.x >= scaledBoundsTopLeft.dx &&
        tile.y >= scaledBoundsTopLeft.dy &&
        tile.x < scaledBoundsBottomRight.dx &&
        tile.y < scaledBoundsBottomRight.dy;
  }
}
