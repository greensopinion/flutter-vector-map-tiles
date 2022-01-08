import 'package:test/test.dart';
import 'package:vector_map_tiles/src/tile_identity.dart';

void main() {
  test('provides contains for smaller into higher level tile', () {
    final tile = TileIdentity(2, 0, 0);
    expect(tile.contains(tile), true);
    expect(tile.contains(TileIdentity(3, 0, 0)), true);
    expect(tile.contains(TileIdentity(3, 1, 0)), true);
    expect(tile.contains(TileIdentity(3, 2, 0)), false);
    expect(tile.contains(TileIdentity(3, 3, 0)), false);
    expect(tile.contains(TileIdentity(3, 1, 1)), true);
    expect(tile.contains(TileIdentity(3, 1, 2)), false);
  });

  test('provides contains for adjacent tiles', () {
    final tile = TileIdentity(2, 1, 1);
    expect(tile.contains(tile), true);
    expect(tile.contains(TileIdentity(2, 2, 1)), false);
    expect(tile.contains(TileIdentity(2, 0, 2)), false);
    expect(tile.contains(TileIdentity(2, 0, 1)), false);
  });
}
