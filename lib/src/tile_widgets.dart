import 'package:flutter/widgets.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import 'grid_layer.dart';
import 'tile_identity.dart';
import 'tile_pair_cache.dart';
import 'vector_tile_provider.dart';
import 'grid_vector_tile.dart';

class TileWidgets {
  Map<TileIdentity, Widget> _idToWidget = {};
  final ZoomScaleFunction _zoomScaleFunction;
  final ZoomFunction _zoomFunction;
  final Theme _theme;
  final RenderMode _renderMode;
  late final TilePairCache _cache;

  TileWidgets(VectorTileProvider tileProvider, this._zoomScaleFunction,
      this._zoomFunction, this._theme, this._renderMode) {
    _cache = TilePairCache(_theme, tileProvider, _renderMode);
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
        cache: _cache,
        zoomScaleFunction: _zoomScaleFunction,
        zoomFunction: _zoomFunction,
        theme: _theme);
  }
}
