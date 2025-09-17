import 'package:executor_lib/executor_lib.dart';
import 'package:flutter/material.dart';

import '../layout/tile_position.dart';
import '../loader/no_op_tile_loader.dart';
import '../loader/tile_loader.dart';
import '../model/map_properties.dart';
import 'abstract_map_layer_state.dart';

class TilePositioningDebugLayer extends AbstractMapLayer {
  const TilePositioningDebugLayer({super.key, required super.mapProperties})
    : super(tileLoaderFactory: _noOpTileLoader);

  @override
  State<StatefulWidget> createState() => TilePositioningDebugLayerState();
}

class TilePositioningDebugLayerState
    extends AbstractMapLayerState<TilePositioningDebugLayer> {
  TilePositioningDebugLayerState();

  @override
  Widget build(BuildContext context) {
    updateTiles(context);
    final tilePositions = mapTiles.tileModels
        .map((m) => m.tilePosition)
        .toList();
    if (tilePositions.isEmpty) {
      return const Center(child: Text('No tiles to display'));
    }
    return Stack(children: tilePositions.map(_toTile).toList());
  }

  Widget _toTile(TilePosition tilePosition) {
    return Positioned(
      left: tilePosition.position.topLeft.dx,
      top: tilePosition.position.topLeft.dy,
      width: tilePosition.position.size.width,
      height: tilePosition.position.size.height,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 1),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Tile: ${tilePosition.tile}'),
              Text('Size: ${tilePosition.position.size}'),
            ],
          ),
        ),
      ),
    );
  }
}

TileLoader _noOpTileLoader(MapProperties properties, Executor _) =>
    const NoOpTileLoader();
