import 'dart:ui';

import 'package:latlong2/latlong.dart';
import 'package:test/test.dart';
import 'package:vector_map_tiles/src/layout/tile_layout.dart';
import 'package:vector_map_tiles/src/layout/tile_viewport.dart';
import 'package:vector_map_tiles/src/tile_identity.dart';
import 'package:vector_map_tiles/src/tile_offset.dart';

import '../mocks/mock_map_state.dart';
import '../mocks/mock_zoom_scaler.dart';

void main() {
  group('TileLayout', () {
    group('computeTilePositions', () {
      test('generates tile positions for single tile viewport', () {
        final layout = TileLayout(
          offset: TileOffset.DEFAULT,
          viewport: TileViewport(
            zoom: 2,
            bounds: const Rect.fromLTRB(1.0, 1.0, 1.9, 1.9),
          ),
          tileSize: 256,
        );
        final mapState = MockMapState(
          center: LatLng(0.0, 0.0),
          zoom: 2.0,
          pixelOrigin: const Offset(256, 256),
          size: const Size(512, 512),
        );
        final zoomScaler = MockZoomScaler(1.0);

        final positions = layout.computeTilePositions(mapState, zoomScaler);

        expect(positions.length, equals(4));
        final tiles = positions.map((p) => p.tile).toSet();
        expect(tiles, contains(TileIdentity(2, 1, 1)));
        expect(tiles, contains(TileIdentity(2, 1, 2)));
        expect(tiles, contains(TileIdentity(2, 2, 1)));
        expect(tiles, contains(TileIdentity(2, 2, 2)));
      });

      test('generates tile positions for multi-tile viewport', () {
        final layout = TileLayout(
          offset: TileOffset.DEFAULT,
          viewport: TileViewport(
            zoom: 2,
            bounds: const Rect.fromLTRB(0.0, 0.0, 1.5, 1.5),
          ),
          tileSize: 256,
        );
        final mapState = MockMapState(
          center: LatLng(0.0, 0.0),
          zoom: 2.0,
          pixelOrigin: Offset.zero,
          size: const Size(512, 512),
        );
        final zoomScaler = MockZoomScaler(1.0);

        final positions = layout.computeTilePositions(mapState, zoomScaler);

        expect(positions.length, equals(9));
        final tiles = positions.map((p) => p.tile).toSet();
        expect(tiles, contains(TileIdentity(2, 0, 0)));
        expect(tiles, contains(TileIdentity(2, 0, 1)));
        expect(tiles, contains(TileIdentity(2, 0, 2)));
        expect(tiles, contains(TileIdentity(2, 1, 0)));
        expect(tiles, contains(TileIdentity(2, 1, 1)));
        expect(tiles, contains(TileIdentity(2, 1, 2)));
        expect(tiles, contains(TileIdentity(2, 2, 0)));
        expect(tiles, contains(TileIdentity(2, 2, 1)));
        expect(tiles, contains(TileIdentity(2, 2, 2)));
      });

      test('calculates correct tile positions with zoom scaling', () {
        final layout = TileLayout(
          offset: TileOffset.DEFAULT,
          viewport: TileViewport(
            zoom: 2,
            bounds: const Rect.fromLTRB(1.0, 1.0, 1.9, 1.9),
          ),
          tileSize: 256,
        );
        final mapState = MockMapState(
          center: LatLng(0.0, 0.0),
          zoom: 2.0,
          pixelOrigin: const Offset(256, 256),
          size: const Size(512, 512),
        );
        final zoomScaler = MockZoomScaler(2.0);

        final positions = layout.computeTilePositions(mapState, zoomScaler);

        expect(positions.length, equals(4));
        final tiles = positions.map((p) => p.tile).toSet();
        expect(tiles, contains(TileIdentity(2, 1, 1)));
        expect(tiles, contains(TileIdentity(2, 1, 2)));
        expect(tiles, contains(TileIdentity(2, 2, 1)));
        expect(tiles, contains(TileIdentity(2, 2, 2)));
        expect(positions.first.position.width, greaterThan(0));
        expect(positions.first.position.height, greaterThan(0));
      });

      test('handles viewport bounds that span multiple tiles', () {
        final layout = TileLayout(
          offset: TileOffset.DEFAULT,
          viewport: TileViewport(
            zoom: 3,
            bounds: const Rect.fromLTRB(2.2, 1.8, 4.7, 3.3),
          ),
          tileSize: 256,
        );
        final mapState = MockMapState(
          center: LatLng(0.0, 0.0),
          zoom: 3.0,
          pixelOrigin: const Offset(512, 512),
          size: const Size(512, 512),
        );
        final zoomScaler = MockZoomScaler(1.0);

        final positions = layout.computeTilePositions(mapState, zoomScaler);

        expect(positions.length, equals(16));
        final tiles = positions.map((p) => p.tile).toSet();
        expect(tiles.length, equals(16));

        for (int x = 2; x <= 5; x++) {
          for (int y = 1; y <= 4; y++) {
            expect(tiles, contains(TileIdentity(3, x, y)));
          }
        }
      });

      test('generates positions with correct tile size scaling', () {
        final layout = TileLayout(
          offset: TileOffset.DEFAULT,
          viewport: TileViewport(
            zoom: 1,
            bounds: const Rect.fromLTRB(0.0, 0.0, 0.9, 0.9),
          ),
          tileSize: 512,
        );
        final mapState = MockMapState(
          center: LatLng(0.0, 0.0),
          zoom: 1.0,
          pixelOrigin: Offset.zero,
          size: const Size(512, 512),
        );
        final zoomScaler = MockZoomScaler(1.0);

        final positions = layout.computeTilePositions(mapState, zoomScaler);

        expect(positions.length, equals(4));
        final tiles = positions.map((p) => p.tile).toSet();
        expect(tiles, contains(TileIdentity(1, 0, 0)));
        expect(tiles, contains(TileIdentity(1, 1, 0)));
        expect(tiles, contains(TileIdentity(1, 0, 1)));
        expect(tiles, contains(TileIdentity(1, 1, 1)));
      });

      test('handles negative viewport bounds', () {
        final layout = TileLayout(
          offset: TileOffset.DEFAULT,
          viewport: TileViewport(
            zoom: 2,
            bounds: const Rect.fromLTRB(-1.5, -0.5, 0.5, 1.5),
          ),
          tileSize: 256,
        );
        final mapState = MockMapState(
          center: LatLng(0.0, 0.0),
          zoom: 2.0,
          pixelOrigin: const Offset(256, 256),
          size: const Size(512, 512),
        );
        final zoomScaler = MockZoomScaler(1.0);

        final positions = layout.computeTilePositions(mapState, zoomScaler);

        expect(positions.length, equals(12));
        final tiles = positions.map((p) => p.tile).toSet();
        expect(tiles.length, equals(12));

        expect(tiles, contains(TileIdentity(2, 0, 0)));
        expect(tiles, contains(TileIdentity(2, 0, 1)));
        expect(tiles, contains(TileIdentity(2, 0, 2)));
        expect(tiles, contains(TileIdentity(2, 1, 0)));
        expect(tiles, contains(TileIdentity(2, 1, 1)));
        expect(tiles, contains(TileIdentity(2, 1, 2)));
        expect(tiles, contains(TileIdentity(2, 2, 0)));
        expect(tiles, contains(TileIdentity(2, 2, 1)));
        expect(tiles, contains(TileIdentity(2, 2, 2)));
        expect(tiles, contains(TileIdentity(2, 3, 0)));
        expect(tiles, contains(TileIdentity(2, 3, 1)));
        expect(tiles, contains(TileIdentity(2, 3, 2)));
      });

      test('produces consistent results for identical inputs', () {
        final layout = TileLayout(
          offset: TileOffset.DEFAULT,
          viewport: TileViewport(
            zoom: 2,
            bounds: const Rect.fromLTRB(1.0, 1.0, 2.0, 2.0),
          ),
          tileSize: 256,
        );
        final mapState = MockMapState(
          center: LatLng(45.0, -122.0),
          zoom: 2.0,
          pixelOrigin: const Offset(256, 256),
          size: const Size(800, 600),
        );
        final zoomScaler = MockZoomScaler(1.5);

        final positions1 = layout.computeTilePositions(mapState, zoomScaler);
        final positions2 = layout.computeTilePositions(mapState, zoomScaler);

        expect(positions1.length, equals(positions2.length));
        for (int i = 0; i < positions1.length; i++) {
          expect(positions1[i].tile, equals(positions2[i].tile));
          expect(positions1[i].position, equals(positions2[i].position));
        }
      });

      test('handles fractional viewport bounds correctly', () {
        final layout = TileLayout(
          offset: TileOffset.DEFAULT,
          viewport: TileViewport(
            zoom: 2,
            bounds: const Rect.fromLTRB(0.3, 0.7, 1.2, 1.8),
          ),
          tileSize: 256,
        );
        final mapState = MockMapState(
          center: LatLng(0.0, 0.0),
          zoom: 2.0,
          pixelOrigin: const Offset(128, 128),
          size: const Size(256, 256),
        );
        final zoomScaler = MockZoomScaler(1.0);

        final positions = layout.computeTilePositions(mapState, zoomScaler);

        expect(positions.length, equals(9));
        final tiles = positions.map((p) => p.tile).toSet();
        expect(tiles, contains(TileIdentity(2, 0, 0)));
        expect(tiles, contains(TileIdentity(2, 1, 0)));
        expect(tiles, contains(TileIdentity(2, 2, 0)));
        expect(tiles, contains(TileIdentity(2, 0, 1)));
        expect(tiles, contains(TileIdentity(2, 1, 1)));
        expect(tiles, contains(TileIdentity(2, 2, 1)));
        expect(tiles, contains(TileIdentity(2, 0, 2)));
        expect(tiles, contains(TileIdentity(2, 1, 2)));
        expect(tiles, contains(TileIdentity(2, 2, 2)));
      });
    });

    group('edge cases', () {
      test('handles empty viewport bounds', () {
        final layout = TileLayout(
          offset: TileOffset.DEFAULT,
          viewport: TileViewport(
            zoom: 1,
            bounds: const Rect.fromLTRB(1.0, 1.0, 1.0, 1.0),
          ),
          tileSize: 256,
        );
        final mapState = MockMapState(
          center: LatLng(0.0, 0.0),
          zoom: 1.0,
          pixelOrigin: Offset.zero,
          size: const Size(256, 256),
        );
        final zoomScaler = MockZoomScaler(1.0);

        final positions = layout.computeTilePositions(mapState, zoomScaler);

        expect(positions.length, equals(1));
        expect(positions.first.tile, equals(TileIdentity(1, 1, 1)));
      });

      test('handles very high zoom levels', () {
        final layout = TileLayout(
          offset: TileOffset.DEFAULT,
          viewport: TileViewport(
            zoom: 18,
            bounds: const Rect.fromLTRB(100000.0, 100000.0, 100000.9, 100000.9),
          ),
          tileSize: 256,
        );
        final mapState = MockMapState(
          center: LatLng(0.0, 0.0),
          zoom: 18.0,
          pixelOrigin: const Offset(25600000, 25600000),
          size: const Size(256, 256),
        );
        final zoomScaler = MockZoomScaler(1.0);

        final positions = layout.computeTilePositions(mapState, zoomScaler);

        expect(positions.length, equals(4));
        final tiles = positions.map((p) => p.tile).toSet();
        expect(tiles, contains(TileIdentity(18, 100000, 100000)));
        expect(tiles, contains(TileIdentity(18, 100000, 100001)));
        expect(tiles, contains(TileIdentity(18, 100001, 100000)));
        expect(tiles, contains(TileIdentity(18, 100001, 100001)));
      });

      test('handles zero zoom scale', () {
        final layout = TileLayout(
          offset: TileOffset.DEFAULT,
          viewport: TileViewport(
            zoom: 1,
            bounds: const Rect.fromLTRB(0.0, 0.0, 0.9, 0.9),
          ),
          tileSize: 256,
        );
        final mapState = MockMapState(
          center: LatLng(0.0, 0.0),
          zoom: 1.0,
          pixelOrigin: Offset.zero,
          size: const Size(256, 256),
        );
        final zoomScaler = MockZoomScaler(0.0);

        final positions = layout.computeTilePositions(mapState, zoomScaler);

        expect(positions.length, equals(4));
        final tiles = positions.map((p) => p.tile).toSet();
        expect(tiles, contains(TileIdentity(1, 0, 0)));
        expect(tiles, contains(TileIdentity(1, 1, 0)));
        expect(tiles, contains(TileIdentity(1, 0, 1)));
        expect(tiles, contains(TileIdentity(1, 1, 1)));
      });

      test('handles very large tile size', () {
        final layout = TileLayout(
          offset: TileOffset.DEFAULT,
          viewport: TileViewport(
            zoom: 1,
            bounds: const Rect.fromLTRB(0.0, 0.0, 0.9, 0.9),
          ),
          tileSize: 2048,
        );
        final mapState = MockMapState(
          center: LatLng(0.0, 0.0),
          zoom: 1.0,
          pixelOrigin: Offset.zero,
          size: const Size(2048, 2048),
        );
        final zoomScaler = MockZoomScaler(1.0);

        final positions = layout.computeTilePositions(mapState, zoomScaler);

        expect(positions.length, equals(4));
        final tiles = positions.map((p) => p.tile).toSet();
        expect(tiles, contains(TileIdentity(1, 0, 0)));
        expect(tiles, contains(TileIdentity(1, 1, 0)));
        expect(tiles, contains(TileIdentity(1, 0, 1)));
        expect(tiles, contains(TileIdentity(1, 1, 1)));
      });
    });
  });
}
