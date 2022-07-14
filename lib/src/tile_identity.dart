import 'dart:math';
import 'dart:ui';

import 'package:flutter_map/plugin_api.dart';

class TileIdentity extends CustomPoint<int> {
  final int z;

  TileIdentity(int z, int x, int y)
      : z = z.toInt(),
        super(x, y);

  @override
  operator ==(o) => o is TileIdentity && x == o.x && y == o.y && z == o.z;

  @override
  int get hashCode => hashValues(x, y, z);

  @override
  String toString() => key();

  String key() => 'z=$z,x=$x,y=$y';

  TileIdentity normalize() {
    final maxX = pow(2, z).toInt();
    if (x >= 0 && x < maxX) {
      return this;
    }
    var normalizedX = x;
    while (normalizedX >= maxX) {
      normalizedX -= maxX;
    }
    while (normalizedX < 0) {
      normalizedX += maxX;
    }
    return TileIdentity(z, normalizedX, y);
  }

  bool overlaps(TileIdentity other) {
    return contains(other) || other.contains(this);
  }

  bool contains(TileIdentity other) {
    final zoomDifference = other.z - z;
    if (zoomDifference == 0) {
      return this == other;
    } else if (zoomDifference < 0) {
      return false;
    }
    final divisor = pow(2, zoomDifference).toInt();
    final translatedX = other.x ~/ divisor;
    final translatedY = other.y ~/ divisor;
    return translatedX == x && translatedY == y;
  }
}
