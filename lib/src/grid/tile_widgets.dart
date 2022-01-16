import 'package:flutter/widgets.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../../vector_map_tiles.dart';
import '../stream/tile_supplier.dart';
import '../tile_viewport.dart';
import 'grid_vector_tile.dart';
import 'tile_model.dart';

class TileWidgets extends ChangeNotifier {
  bool _disposed = false;
  Map<TileIdentity, VectorTileModel> _idToModel = {};
  Map<TileIdentity, VectorTileModel> _temporaryRetainModels = {};
  Map<TileIdentity, VectorTileModel> _loadingModels = {};
  Map<TileIdentity, GridVectorTile> _idToWidget = {};
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

    tiles.forEach((tile) {
      var model = previousIdToModel[tile];
      if (model == null) {
        model = VectorTileModel(
            _renderMode,
            _tileSupplier,
            _theme,
            tile,
            _zoomScaleFunction,
            _zoomFunction,
            paintBackground,
            showTileDebugInfo);
        model.addListener(_scheduleClearNewModels);
        _loadingModels[tile] = model;
        model.startLoading();
      } else {
        previousIdToModel.remove(tile);
      }
      _idToModel[tile] = model;
    });
    final newZoom = viewport.zoom;
    final entriesToRemove = previousIdToModel.entries.where((previousEntry) {
      if (previousEntry.key.z != newZoom && !previousEntry.value.hasData) {
        return true;
      }
      final zoomDifference = previousEntry.key.z - newZoom;
      if (zoomDifference > _maxSmallerZoomDifference ||
          zoomDifference < _maxLargerZoomDifference) {
        return true;
      }
      if (!viewport.overlaps(previousEntry.key)) {
        return true;
      }
      return false;
    }).toList();
    entriesToRemove.forEach((toDispose) {
      previousIdToModel.remove(toDispose.key);
    });
    _temporaryRetainModels = previousIdToModel;
    _temporaryRetainModels.forEach((key, value) {
      _idToModel[key] = value;
    });
    notifyListeners();
  }

  void _scheduleClearNewModels() {
    if (_loadingModels.length == 1) {
      _clearNewModels();
    } else {
      Future.delayed(Duration(milliseconds: 100))
          .then((_) => _clearNewModels());
    }
  }

  void _clearNewModels() {
    if (_loadingModels.isNotEmpty) {
      final readyModels =
          _loadingModels.values.where((m) => m.hasData).toList();
      readyModels.forEach((m) {
        m.removeListener(_scheduleClearNewModels);
        _loadingModels.remove(m.tile);
      });
      if (_loadingModels.isEmpty) {
        _removeObsoleteModels();
      } else {
        _pruneObsoleteModels();
      }
      notifyListeners();
    }
  }

  void _removeObsoleteModels() {
    _temporaryRetainModels.forEach((tile, model) {
      _idToModel.remove(tile);
      _loadingModels.remove(tile);
    });
    _temporaryRetainModels.clear();
  }

  void _pruneObsoleteModels() {
    final allObsoleteEntries = _temporaryRetainModels.entries.toList();
    allObsoleteEntries.forEach((entry) {
      final obsoleteModel = entry.value;

      final containing = _idToModel.values.any((candidate) =>
          candidate.hasData &&
          !_temporaryRetainModels.containsKey(candidate.tile) &&
          candidate.tile.contains(obsoleteModel.tile));
      var shouldRemove = containing;
      if (!shouldRemove) {
        final contained = _idToModel.values.where((candidate) =>
            !_temporaryRetainModels.containsKey(candidate.tile) &&
            obsoleteModel.tile.contains(candidate.tile));
        shouldRemove =
            contained.isNotEmpty && contained.every((model) => model.hasData);
      }
      if (shouldRemove) {
        _temporaryRetainModels.remove(entry.key);
        _idToModel.remove(entry.key);
        _loadingModels.remove(entry.key);
      }
    });
  }

  void dispose() {
    if (!_disposed) {
      super.dispose();
      _disposed = true;
      _idToWidget.clear();
      _idToModel.values.forEach((model) => model.dispose());
      _idToModel.clear();
      _loadingModels.clear();
      _temporaryRetainModels.clear();
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
}

// The larger the allowable difference, the more likely that map data will
// be drawn to screen while zooming when new tiles need to be loaded, since
// existing tiles can be drawn in place of new ones.
//
// A larger zoom difference also results in higher memory consumption since
// off-screen painting onto a canvas consumes a lot of memory, and can
// result in app crashes.
final _maxSmallerZoomDifference = 2;
final _maxLargerZoomDifference = -1;
