import 'package:flutter/widgets.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import 'tile_identity.dart';
import 'vector_tile_provider.dart';
import 'grid_vector_tile.dart';

class TileWidgets {
  Map<TileIdentity, Widget> _idToWidget = {};
  final VectorTileProvider _tileProvider;
  final ZoomScaleFunction _zoomScaleFunction;
  final ZoomFunction _zoomFunction;
  final Theme _theme;

  TileWidgets(this._tileProvider, this._zoomScaleFunction, this._zoomFunction,
      this._theme);

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
        tileProvider: _tileProvider,
        zoomScaleFunction: _zoomScaleFunction,
        zoomFunction: _zoomFunction,
        theme: _theme);
  }
}
