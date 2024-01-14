import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../../vector_map_tiles.dart';
import '../cache/text_cache.dart';
import '../stream/tile_supplier.dart';
import '../stream/tile_supplier_raster.dart';
import '../tile_viewport.dart';
import 'grid_vector_tile.dart';
import 'slippy_map_translator.dart';
import 'tile_model.dart';
import 'tile_zoom.dart';

class TileWidgets extends ChangeNotifier {
  bool _disposed = false;
  Map<TileIdentity, VectorTileModel> _idToModel = {};
  Map<TileIdentity, GridVectorTile> _idToWidget = {};
  final List<VectorTileModel> _loadingModels = [];
  List<VectorTileModel> _substitutionModels = [];
  final ZoomScaleFunction _zoomScaleFunction;
  final ZoomFunction _zoomFunction;
  final ZoomFunction _zoomDetailFunction;
  final RotationFunction _rotationFunction;
  final Theme _theme;
  final Theme? _symbolTheme;
  final SpriteStyle? _sprites;
  final Future<ui.Image> Function()? _spriteAtlasProvider;
  final TileProvider _tileProvider;
  final RasterTileProvider _rasterTileProvider;
  final TextCache _textCache;
  final bool paintBackground;
  final bool showTileDebugInfo;
  final int maxSubstitutionDifference;
  final int tileZoomSubstitutionOffset;

  TileWidgets(
      this._zoomScaleFunction,
      this._zoomFunction,
      this._zoomDetailFunction,
      this._rotationFunction,
      this._theme,
      this._symbolTheme,
      this._sprites,
      this._spriteAtlasProvider,
      this._tileProvider,
      this._rasterTileProvider,
      this._textCache,
      this.maxSubstitutionDifference,
      this.tileZoomSubstitutionOffset,
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
    if (maxSubstitutionDifference > 0 && effectiveTiles.isNotEmpty) {
      final z = effectiveTiles.first.z;
      final obsoleteSubstitutions = _substitutionModels
          .where((m) =>
              m.disposed || (m.tile.z - z).abs() > maxSubstitutionDifference)
          .toList();
      for (final obsolete in obsoleteSubstitutions) {
        _removeAndDispose(obsolete);
      }
    }
    for (final tile in effectiveTiles) {
      var model = previousIdToModel[tile];
      if (model != null && model.disposed) {
        _removeAndDispose(model);
        previousIdToModel.remove(tile);
        model = null;
      }
      if (model == null) {
        model = VectorTileModel(
            _tileProvider,
            _rasterTileProvider,
            _theme,
            _symbolTheme,
            _sprites,
            _spriteAtlasProvider,
            tile,
            tileZoomSubstitutionOffset,
            TileStateProvider(tile, _zoomScaleFunction, _zoomFunction,
                _zoomDetailFunction, _rotationFunction),
            paintBackground,
            showTileDebugInfo);
        model.addListener(_modelChanged);
        _loadingModels.add(model);
        model.startLoading();
      } else {
        previousIdToModel.remove(tile);
      }
      _idToModel[tile] = model;
    }
    if (maxSubstitutionDifference > 0 && _loadingModels.isNotEmpty) {
      _substitutionModels =
          _substitutionTiles(previousIdToModel, _loadingModels);
      for (final model in _idToModel.values) {
        model.showLabels = true;
      }
      for (final substitution in _substitutionModels) {
        previousIdToModel.remove(substitution.tile);
        _idToModel[substitution.tile] = substitution;
        substitution.showLabels = false;
      }
    }
    for (final it in previousIdToModel.values) {
      _removeAndDispose(it);
    }
    notifyListeners();
    _propagateUpdated();
  }

  @override
  void dispose() {
    if (!_disposed) {
      super.dispose();
      _disposed = true;
      _idToWidget.clear();
      _idToModel.values.toList().forEach(_removeAndDispose);
      _idToModel.clear();
      _loadingModels.clear();
      _substitutionModels.clear();
    }
  }

  void _modelChanged() {
    if (_disposed) {
      return;
    }
    var loaded = _loadingModels.where((model) => model.hasData).toList();
    if (loaded.isNotEmpty) {
      bool changed = false;
      for (final model in loaded) {
        _loadingModels.remove(model);
        model.removeListener(_modelChanged);
        changed =
            changed || (!model.disposed && _idToModel.containsKey(model.tile));
      }
      if (changed) {
        for (final substitution in _substitutionModels.toList()) {
          final overlappingTiles = _idToModel.values.where((m) =>
              m.tile != substitution.tile &&
              m.tile.overlaps(substitution.tile));
          if (overlappingTiles.every((m) => m.hasData)) {
            _removeAndDispose(substitution);
          }
        }
        notifyListeners();
      }
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
      var previous = _idToWidget[tile];
      if (previous != null && previous.model.disposed) {
        previous = null;
      }
      idToWidget[tile] = previous ?? _createWidget(model);
    });
    _idToWidget = idToWidget;
  }

  GridVectorTile _createWidget(VectorTileModel model) {
    final tile = model.tile;
    return GridVectorTile(
        key: Key('GridTile_${tile.z}_${tile.x}_${tile.y}_${_theme.id}'),
        model: model,
        textCache: _textCache);
  }

  Set<TileIdentity> _reduce(List<TileIdentity> tiles) {
    final translator = SlippyMapTranslator(_tileProvider.maximumZoom);
    final reduced = <TileIdentity>{};
    for (final tile in tiles) {
      final zoomStep = tile.z > _tileProvider.maximumZoom ? tile.z : tile.z;
      final translation =
          translator.specificZoomTranslation(tile, zoom: zoomStep);
      reduced.add(translation.translated);
    }
    return reduced;
  }

  List<VectorTileModel> _substitutionTiles(
          Map<TileIdentity, VectorTileModel> possibleSubstitutions,
          List<VectorTileModel> loadingModels) =>
      possibleSubstitutions.values
          .where((candidate) => candidate.hasData && !candidate.disposed)
          .where((candidate) => loadingModels.any((m) {
                final zoomDiff = (m.tile.z - candidate.tile.z).abs();
                return zoomDiff > 0 &&
                    zoomDiff <= maxSubstitutionDifference &&
                    m.tile.overlaps(candidate.tile);
              }))
          .toList();

  void _removeAndDispose(VectorTileModel obsolete) {
    _substitutionModels.remove(obsolete);
    _loadingModels.remove(obsolete);
    _idToModel.remove(obsolete.tile);
    _idToWidget.remove(obsolete.tile);
    obsolete.dispose();
  }

  void _propagateUpdated() {
    for (final model in _idToModel.values) {
      if (!_loadingModels.contains(model)) {
        model.stateUpdated();
      }
    }
  }
}
