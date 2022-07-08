import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'model.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

class MapWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider<MapModel>(
        create: (_) => MapModel()..load(),
        builder: (context, _) =>
            Consumer<MapModel>(builder: (context, model, _) {
          if (model.loading) {
            return const Center(child: CircularProgressIndicator());
          } else if (model.theme == null) {
            return const Text("Oh no!");
          }
          return FlutterMap(
            options: MapOptions(
                center: LatLng(49.246292, -123.116226),
                zoom: 10,
                maxZoom: 22,
                interactiveFlags: InteractiveFlag.drag |
                    InteractiveFlag.flingAnimation |
                    InteractiveFlag.pinchMove |
                    InteractiveFlag.pinchZoom |
                    InteractiveFlag.doubleTapZoom,
                plugins: [VectorMapTilesPlugin()]),
            layers: <LayerOptions>[
              VectorTileLayerOptions(
                  theme: model.theme!,
                  backgroundTheme: model.theme!.copyWith(
                      types: {ThemeLayerType.background, ThemeLayerType.fill}),
                  tileOffset: TileOffset.mapbox,
                  tileProviders:
                      TileProviders({'composite': model.tileProvider()})),
            ],
          );
        }),
      );
}
