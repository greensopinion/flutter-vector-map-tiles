import 'package:flutter/widgets.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../../vector_map_tiles.dart';
import '../stream/tile_supplier.dart';
import 'grid_vector_tile.dart';
import 'tile_model.dart';

class TileWidgets extends ChangeNotifier {
  bool _disposed = false;
  Map<TileIdentity, VectorTileModel> _idToModel = {};
  Map<TileIdentity, VectorTileModel> _obsoleteModels = {};
  List<VectorTileModel> _newModels = [];
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

  void update(List<TileIdentity> tiles) {
    if (tiles.isEmpty || _disposed) {
      return;
    }
    _updateModels(tiles);
  }

  void updateWidgets() => _updateWidgets();

  bool get hasNewModels => _newModels.isNotEmpty;
  bool get hasObsoleteModels => _obsoleteModels.isNotEmpty;

  Map<TileIdentity, GridVectorTile> get all => _idToWidget;

  void _updateModels(List<TileIdentity> tiles) {
    final newZoom = tiles.first.z;
    final obsoleteNewModels =
        _newModels.where((newModel) => newModel.tile.z != newZoom).toList();
    obsoleteNewModels.forEach((obsoleteNewModel) {
      _newModels.remove(obsoleteNewModel);
      _obsoleteModels[obsoleteNewModel.tile] = obsoleteNewModel;
    });

    Map<TileIdentity, VectorTileModel> idToModel = {};
    tiles.forEach((tile) {
      var model = _idToModel[tile] ?? _obsoleteModels[tile];
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
        _newModels.add(model);
        model.addListener(_scheduleClearNewModels);
        model.startLoading();
      } else {
        _idToModel.remove(tile);
        _obsoleteModels.remove(tile);
      }
      idToModel[tile] = model;
    });
    _obsoleteModels.addAll(_idToModel);
    final entriesToDiscard = _obsoleteModels.entries
        .where((entry) => (entry.key.z - newZoom).abs() > _maxZoomDifference)
        .toList();
    entriesToDiscard.forEach((entry) {
      _obsoleteModels.remove(entry.key);
      entry.value.dispose();
    });
    idToModel.addAll(_obsoleteModels);
    _idToModel = idToModel;
    if (_newModels.isEmpty) {
      _removeObsoleteModels();
    }
  }

  void _scheduleClearNewModels() {
    if (_newModels.length == 1) {
      _clearNewModels();
    } else {
      Future.delayed(Duration(milliseconds: 100))
          .then((_) => _clearNewModels());
    }
  }

  void _clearNewModels() {
    if (_newModels.isNotEmpty) {
      final readyModels =
          _newModels.where((m) => m.hasData || m.disposed).toList();
      readyModels.forEach((m) {
        if (!m.disposed) {
          _idToModel[m.tile] = m;
        }
        m.removeListener(_scheduleClearNewModels);
        _newModels.remove(m);
      });
      if (_newModels.isEmpty) {
        _removeObsoleteModels();
      } else {
        _pruneObsoleteModels();
      }
      notifyListeners();
    }
  }

  void _removeObsoleteModels() {
    if (_obsoleteModels.isNotEmpty) {
      _obsoleteModels.forEach((tile, model) {
        _idToModel.remove(tile);
        model.dispose();
      });
      _obsoleteModels.clear();
    }
  }

  void _pruneObsoleteModels() {
    final allObsoleteEntries = _obsoleteModels.entries.toList();
    allObsoleteEntries.forEach((entry) {
      final obsoleteModel = entry.value;

      final containing = _idToModel.values.any((candidate) =>
          candidate.hasData &&
          !_obsoleteModels.containsKey(candidate.tile) &&
          candidate.tile.contains(obsoleteModel.tile));
      var shouldRemove = containing;
      if (!shouldRemove) {
        final contained = _idToModel.values.where((candidate) =>
            !_obsoleteModels.containsKey(candidate.tile) &&
            obsoleteModel.tile.contains(candidate.tile));
        shouldRemove =
            contained.isNotEmpty && contained.every((model) => model.hasData);
      }
      if (shouldRemove) {
        _obsoleteModels.remove(entry.key);
        _idToModel.remove(entry.key);
        obsoleteModel.dispose();
      }
    });
  }

  void dispose() {
    super.dispose();
    _disposed = true;
    _idToModel.values.forEach((model) => model.dispose());
    _idToModel.clear();
    _obsoleteModels.clear();
    _newModels.clear();
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

final _maxZoomDifference = 2;
