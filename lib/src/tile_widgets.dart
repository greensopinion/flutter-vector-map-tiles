import 'package:flutter/widgets.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import 'tile_identity.dart';
import 'vector_tile_provider.dart';
import 'grid_vector_tile.dart';
import 'vector_tiles.dart';

class TileWidgets {
  Map<TileIdentity, Widget> _idToWidget = {};
  final ZoomScaleFunction _zoomScaleFunction;
  final ZoomFunction _zoomFunction;
  final Theme _theme;
  late final VectorTiles _vectorTiles;

  TileWidgets(VectorTileProvider tileProvider, this._zoomScaleFunction,
      this._zoomFunction, this._theme) {
    _vectorTiles = VectorTiles(tileProvider);
  }

  void update(List<TileIdentity> tiles) {
    if (tiles.isEmpty) {
      return;
    }
    Map<TileIdentity, Widget> idToWidget = {};
    tiles.forEach((tile) {
      idToWidget[tile] = _idToWidget[tile] ?? _createWidget(tile);
    });
    _idToWidget = idToWidget;
  }

  Map<TileIdentity, Widget> get all => _idToWidget;

  Widget _createWidget(TileIdentity tile) {
    return GridVectorTile(
        key: Key('GridTile_${tile.z}_${tile.x}_${tile.y}'),
        tileIdentity: tile,
        vectorTiles: _vectorTiles,
        zoomScaleFunction: _zoomScaleFunction,
        zoomFunction: _zoomFunction,
        theme: _theme);
  }
}
