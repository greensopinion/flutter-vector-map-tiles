import 'dart:typed_data';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:test/test.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart' hide TileLayer;

void main() {
  test('constructs a vector layer with flutter_map 8.2 APIs', () {
    final layer = VectorTileLayer(
      tileProviders: TileProviders({'offline': _TestTileProvider()}),
      theme: ThemeReader().read(const {
        'version': 8,
        'sources': {
          'offline': {'type': 'vector'},
        },
        'layers': [
          {
            'id': 'offline-fill',
            'type': 'fill',
            'source': 'offline',
            'source-layer': 'land',
            'paint': {'fill-color': '#000000'},
          },
        ],
      }),
    );

    final map = FlutterMap(
      options: const MapOptions(initialCenter: LatLng(0, 0)),
      children: [layer],
    );

    expect(map.children, contains(layer));
  });
}

class _TestTileProvider extends VectorTileProvider {
  @override
  int get maximumZoom => 14;

  @override
  int get minimumZoom => 0;

  @override
  Future<Uint8List> provide(TileIdentity tile) async => Uint8List(0);

  @override
  TileOffset get tileOffset => TileOffset.DEFAULT;
}
