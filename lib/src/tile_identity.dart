import 'dart:ui';

import 'package:flutter_map/plugin_api.dart';

class TileIdentity extends CustomPoint<int> {
  final int z;

  TileIdentity(int z, int x, int y)
      : this.z = z.toInt(),
        super(x, y);

  @override
  operator ==(o) => o is TileIdentity && x == o.x && y == o.y && z == o.z;

  @override
  int get hashCode => hashValues(x, y, z);

  @override
  String toString() => 'TileIdentity(z=$z,x=$x,y=$y)';
}
