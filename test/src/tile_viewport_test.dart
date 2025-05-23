import 'dart:ui';

import 'package:test/test.dart';
import 'package:vector_map_tiles/src/tile_identity.dart';
import 'package:vector_map_tiles/src/tile_viewport.dart';

void main() {
  group('overlaps:', () {
    final viewport = TileViewport(
      2,
      const Rect.fromLTRB(1.0, 1.0, 3.0, 3.0),
    );

    test('when tile is at same zoom', () {
      expect(viewport.overlaps(TileIdentity(2, 0, 0)), false);
      expect(viewport.overlaps(TileIdentity(2, 1, 0)), false);
      expect(viewport.overlaps(TileIdentity(2, 2, 0)), false);
      expect(viewport.overlaps(TileIdentity(2, 3, 0)), false);
      expect(viewport.overlaps(TileIdentity(2, 0, 3)), false);
      expect(viewport.overlaps(TileIdentity(2, 1, 3)), false);
      expect(viewport.overlaps(TileIdentity(2, 2, 3)), false);
      expect(viewport.overlaps(TileIdentity(2, 3, 3)), false);
      expect(viewport.overlaps(TileIdentity(2, 0, 1)), false);
      expect(viewport.overlaps(TileIdentity(2, 0, 2)), false);
      expect(viewport.overlaps(TileIdentity(2, 3, 1)), false);
      expect(viewport.overlaps(TileIdentity(2, 3, 2)), false);

      expect(viewport.overlaps(TileIdentity(2, 1, 1)), true);
      expect(viewport.overlaps(TileIdentity(2, 1, 2)), true);
      expect(viewport.overlaps(TileIdentity(2, 2, 1)), true);
      expect(viewport.overlaps(TileIdentity(2, 2, 2)), true);
    });

    test('when tile is larger', () {
      final viewport = TileViewport(
        3,
        const Rect.fromLTRB(3.0, 2.0, 5.0, 5.0),
      );

      expect(viewport.overlaps(TileIdentity(0, 0, 0)), true);

      for (int x = 0; x < 4; ++x) {
        expect(viewport.overlaps(TileIdentity(2, x, 0)), false, reason: '$x');
        expect(viewport.overlaps(TileIdentity(2, x, 3)), false, reason: '$x');
      }
      for (int y = 0; y < 4; ++y) {
        expect(viewport.overlaps(TileIdentity(2, 0, y)), false, reason: '$y');
        expect(viewport.overlaps(TileIdentity(2, 3, y)), false, reason: '$y');
      }
      expect(viewport.overlaps(TileIdentity(2, 1, 1)), true);
      expect(viewport.overlaps(TileIdentity(2, 2, 1)), true);
      expect(viewport.overlaps(TileIdentity(2, 1, 2)), true);
      expect(viewport.overlaps(TileIdentity(2, 2, 2)), true);
    });

    group('specific cases:', () {
      test('larger tile zoom', () {
        final larger = TileIdentity(11, 325, 703);
        final viewport = TileViewport(
          12,
          const Rect.fromLTRB(649.0, 1404.0, 652.0, 1409.0),
        );
        expect(viewport.overlaps(larger), true);
      });
    });

    test('when tile is smaller', () {
      final viewport = TileViewport(
        2,
        const Rect.fromLTRB(1.0, 1.0, 3.0, 3.0),
      );
      for (int x = 0; x < 2; ++x) {
        for (int y = 0; y < 8; ++y) {
          expect(viewport.overlaps(TileIdentity(3, x, y)), false,
              reason: '$x,$y');
        }
      }
      for (int x = 6; x < 8; ++x) {
        for (int y = 0; y < 8; ++y) {
          expect(viewport.overlaps(TileIdentity(3, x, y)), false,
              reason: '$x,$y');
        }
      }
      for (int x = 0; x < 8; ++x) {
        for (int y = 0; y < 2; ++y) {
          expect(viewport.overlaps(TileIdentity(3, x, y)), false,
              reason: '$x,$y');
        }
      }
      for (int x = 0; x < 8; ++x) {
        for (int y = 6; y < 8; ++y) {
          expect(viewport.overlaps(TileIdentity(3, x, y)), false,
              reason: '$x,$y');
        }
      }
      for (int x = 2; x < 6; ++x) {
        for (int y = 2; y < 6; ++y) {
          expect(viewport.overlaps(TileIdentity(3, x, y)), true,
              reason: '$x,$y');
        }
      }
    });
  });
}
