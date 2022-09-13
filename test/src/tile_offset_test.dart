import 'package:test/test.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';

void main() {
  group('TileOffset', () {
    test('provides a default offset', () {
      const offset = TileOffset.DEFAULT;
      expect(offset.zoomOffset, 0);
    });
    test('provides a relative offset', () {
      final offset = TileOffset.DEFAULT.offsetBy(zoom: -1);
      expect(offset.zoomOffset, -1);
    });
    test('provides a mapbox offset', () {
      final offset = TileOffset.mapbox;
      expect(offset.zoomOffset, -1);
    });
  });
}
