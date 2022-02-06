import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:vector_map_tiles/src/grid/slippy_map_translator.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../../vector_map_tiles.dart';
import '../stream/tile_supplier.dart';
import '../tile_viewport.dart';
import 'grid_vector_tile.dart';
import 'tile_model.dart';

class TileWidgets extends ChangeNotifier {
  bool _disposed = false;
  Map<TileIdentity, VectorTileModel> _idToModel = {};
  Map<TileIdentity, GridVectorTile> _idToWidget = {};
  final ZoomScaleFunction _zoomScaleFunction;
  final ZoomFunction _zoomFunction;
  final Theme _theme;
  final Theme? _symbolTheme;
  final TileSupplier _tileSupplier;
  final RenderMode _renderMode;
  final bool paintBackground;
  final bool showTileDebugInfo;

  TileWidgets(
      this._zoomScaleFunction,
      this._zoomFunction,
      this._theme,
      this._symbolTheme,
      this._tileSupplier,
      this._renderMode,
      this.paintBackground,
      this.showTileDebugInfo);

  void update(TileViewport viewport, List<TileIdentity> tiles) {
    if (tiles.isEmpty || _disposed) {
      return;
    }
    _updateModels(viewport, tiles);
  }

  void updateWidgets() => _updateWidgets();

  Map<TileIdentity, GridVectorTile> get all => _idToWidget;

  void _updateModels(TileViewport viewport, List<TileIdentity> tiles) {
    Map<TileIdentity, VectorTileModel> previousIdToModel = _idToModel;

    _idToModel = {};

    Set<TileIdentity> effectiveTiles = _reduce(tiles);
    effectiveTiles.forEach((tile) {
      var model = previousIdToModel[tile];
      if (model == null) {
        model = VectorTileModel(
            _renderMode,
            _tileSupplier,
            _theme,
            _symbolTheme,
            tile,
            _zoomScaleFunction,
            _zoomFunction,
            paintBackground,
            showTileDebugInfo);
        model.startLoading();
      } else {
        previousIdToModel.remove(tile);
      }
      _idToModel[tile] = model;
    });
    previousIdToModel.values.forEach((it) => it.dispose());
    notifyListeners();
  }

  void dispose() {
    if (!_disposed) {
      super.dispose();
      _disposed = true;
      _idToWidget.clear();
      _idToModel.values.forEach((model) => model.dispose());
      _idToModel.clear();
    }
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  void _updateWidgets() {
    Map<TileIdentity, GridVectorTile> idToWidget = {};
    _idToModel.forEach((tile, model) {
      idToWidget[tile] = _idToWidget[tile] ?? _createWidget(model);
    });
    _idToWidget = idToWidget;
  }

  GridVectorTile _createWidget(VectorTileModel model) {
    final tile = model.tile;
    return GridVectorTile(
        key: Key('GridTile_${tile.z}_${tile.x}_${tile.y}_${_theme.id}'),
        model: model);
  }

  Set<TileIdentity> _reduce(List<TileIdentity> tiles) {
    final translator = SlippyMapTranslator(_tileSupplier.maximumZoom);
    final reduced = <TileIdentity>{};
    for (final tile in tiles) {
      final translation = translator.specificZoomTranslation(tile,
          zoom: min(_tileSupplier.maximumZoom, tile.z));
      reduced.add(translation.translated);
    }
    return reduced;
  }
}
