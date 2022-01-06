import 'package:flutter/widgets.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../../vector_map_tiles.dart';
import '../stream/tile_supplier.dart';
import 'grid_vector_tile.dart';
import 'tile_model.dart';

class TileWidgets {
  Map<TileIdentity, Widget> _idToWidget = {};
  final ZoomScaleFunction _zoomScaleFunction;
  final ZoomFunction _zoomFunction;
  final Theme _theme;
  final TileSupplier _tileSupplier;
  final RenderMode _renderMode;
  final bool paintBackground;
  final bool showTileDebugInfo;

  TileWidgets(
      this._zoomScaleFunction,
      this._zoomFunction,
      this._theme,
      this._tileSupplier,
      this._renderMode,
      this.paintBackground,
      this.showTileDebugInfo);

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
        key: Key('GridTile_${tile.z}_${tile.x}_${tile.y}_${_theme.id}'),
        tileIdentity: tile,
        renderMode: _renderMode,
        tileSupplier: _tileSupplier,
        zoomScaleFunction: _zoomScaleFunction,
        zoomFunction: _zoomFunction,
        theme: _theme,
        paintBackground: paintBackground,
        showTileDebugInfo: showTileDebugInfo);
  }
}
