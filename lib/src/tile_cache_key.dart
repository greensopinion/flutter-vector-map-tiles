import 'dart:ui';

import 'tile_identity.dart';

class TileCacheKey {
  final int z;
  final int x;
  final int y;

  TileCacheKey(this.z, this.x, this.y);

  @override
  operator ==(o) => o is TileCacheKey && x == o.x && y == o.y && z == o.z;

  @override
  int get hashCode => hashValues(x, y, z);

  @override
  String toString() => 'Tile(z=$z,x=$x,y=$y)';

  TileIdentity toTileIdentity() => TileIdentity(z, x, y);
}

extension TileIdentityExtension on TileIdentity {
  TileCacheKey toCacheKey() => TileCacheKey(z.toInt(), x.toInt(), y.toInt());
}
