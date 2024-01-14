import 'dart:developer';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:executor_lib/executor_lib.dart';
import 'package:flutter/widgets.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../../vector_map_tiles.dart';
import '../profiler.dart';
import '../stream/tile_supplier.dart';
import '../stream/tile_supplier_raster.dart';
import '../stream/translated_tile_request.dart';
import 'slippy_map_translator.dart';
import 'tile_layer_composer.dart';
import 'tile_layer_model.dart';
import 'tile_zoom.dart';

class VectorTileModel extends ChangeNotifier {
  bool _disposed = false;

  bool get disposed => _disposed;

  final TileIdentity tile;
  final int tileZoomSubstitutionOffset;
  final TileProvider tileProvider;
  final RasterTileProvider rasterTileProvider;
  final Theme theme;
  final Theme? symbolTheme;
  final SpriteStyle? sprites;
  ui.Image? spriteImage;
  final Future<ui.Image> Function()? spriteAtlasProvider;
  bool paintBackground;
  final bool showTileDebugInfo;
  final TileStateProvider stateProvider;
  TileState lastRenderedState = TileState.undefined();
  TileIdentity? lastRenderedTile;

  late final TileTranslation defaultTranslation;
  TileTranslation? translation;
  Tileset? tileset;
  RasterTileset? rasterTileset;
  late final TimelineTask _firstRenderedTask;
  bool _firstRendered = false;
  bool showLabels = true;
  final symbolState = VectorTileSymbolState();
  late final List<TileLayerModel> layers;

  VectorTileModel(
      this.tileProvider,
      this.rasterTileProvider,
      this.theme,
      this.symbolTheme,
      this.sprites,
      this.spriteAtlasProvider,
      this.tile,
      this.tileZoomSubstitutionOffset,
      this.stateProvider,
      this.paintBackground,
      this.showTileDebugInfo) {
    layers = TileLayerComposer().compose(this, theme, sprites);
    defaultTranslation =
        SlippyMapTranslator(tileProvider.maximumZoom).translate(tile);
    _firstRenderedTask = tileRenderingTask(tile);
  }

  bool get hasData => tileset != null;

  void rendered() {
    if (!_firstRendered) {
      _firstRendered = true;
      _firstRenderedTask.finish();
    }
  }

  void startLoading() {
    _VectorTileModelLoader(this).startLoading();
  }

  void _receiveTile(TileResponse received, RasterTileset rasterTileset,
      ui.Image? spriteImage) {
    final newTranslation = SlippyMapTranslator(tileProvider.maximumZoom)
        .specificZoomTranslation(tile, zoom: received.identity.z);
    tileset = received.tileset;
    translation = newTranslation;
    this.rasterTileset = rasterTileset;
    this.spriteImage = spriteImage;
    for (final layer in layers) {
      layer.tileset = tileset;
      layer.translation = translation;
      layer.spriteImage = spriteImage;
    }
    if (disposed) {
      _disposeImages();
    }
    notifyListeners();
    _notifyLayers();
  }

  void stateUpdated() {
    if (hasChanged()) {
      notifyListeners();
      _notifyLayers();
    }
  }

  TileState updateRendering() {
    lastRenderedState = stateProvider.provide();
    lastRenderedTile = translation?.translated;
    return lastRenderedState;
  }

  void _notifyLayers() {
    for (final layer in layers) {
      layer.notifyListeners();
    }
  }

  bool hasChanged() =>
      lastRenderedState != stateProvider.provide() ||
      lastRenderedTile != translation?.translated;

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  @override
  void dispose() {
    if (!_disposed) {
      super.dispose();
      _disposed = true;
      for (final layer in layers) {
        layer.dispose();
      }
      if (!_firstRendered) {
        _firstRendered = true;
        _firstRenderedTask.finish(arguments: {'cancelled': true});
      }
      _disposeImages();
    }
  }

  void _disposeImages() {
    rasterTileset?.dispose();
    rasterTileset = null;
  }

  @override
  void removeListener(ui.VoidCallback listener) {
    if (!_disposed) {
      super.removeListener(listener);
    }
  }
}

class VectorTileSymbolState extends ChangeNotifier {
  bool _disposed = false;
  bool _symbolsReady = false;
  bool get symbolsReady => _symbolsReady;

  set symbolsReady(bool ready) {
    if (ready != _symbolsReady) {
      _symbolsReady = ready;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    super.dispose();
    _disposed = true;
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }
}

class _VectorTileModelLoader {
  final VectorTileModel model;

  _VectorTileModelLoader(this.model);

  void startLoading() async {
    final spriteImage = await model.spriteAtlasProvider?.call();
    final originalTile = model.tile.normalize();
    final maxZoom = model.tileProvider.maximumZoom;
    var originalLoaded = false;
    final int startZoom =
        max(1, min(originalTile.z, maxZoom) - model.tileZoomSubstitutionOffset);
    for (int z = startZoom; z >= max(startZoom - 10, 1); --z) {
      final request = createTranslatedRequest(_newRequest(), maximumZoom: z);
      final localTile = await model.tileProvider
          .provideLocalCopy(request)
          .swallowCancellation();
      if (model.disposed) {
        break;
      }
      if (localTile != null && localTile.tileset != null) {
        var rasterTileset = const RasterTileset(tiles: {});
        originalLoaded = z == originalTile.z;
        if (localTile.tileset != null) {
          rasterTileset = await model.rasterTileProvider
              .retrieve(model.tile, skipMissing: true);
        }
        model._receiveTile(localTile, rasterTileset, spriteImage);
        if (model.hasData) {
          break;
        }
      }
    }
    if (!originalLoaded && !model.disposed) {
      try {
        var request = _newRequest();
        if (model.tileZoomSubstitutionOffset > 0 && originalTile.z > 0) {
          request = createTranslatedRequest(request,
              maximumZoom:
                  max(0, originalTile.z - model.tileZoomSubstitutionOffset));
        }
        final loading = model.tileProvider.provide(request);
        final rasterTileset = await model.rasterTileProvider
            .retrieve(model.tile, skipMissing: true);
        late final TileResponse tileResponse;
        try {
          tileResponse = await loading;
        } catch (_) {
          rasterTileset.dispose();
          rethrow;
        }
        model._receiveTile(tileResponse, rasterTileset, spriteImage);
      } catch (e) {
        if (e is SocketException) {
          // nothing to do
        } else if (e is CancellationException) {
          // nothing to do
        } else {
          rethrow;
        }
      }
    }
  }

  TileRequest _newRequest() {
    final zoom = model.stateProvider.provide();
    return TileRequest(
        tileId: model.tile.normalize(),
        zoom: zoom.zoom,
        zoomDetail: zoom.zoomDetail,
        cancelled: () => model.disposed);
  }
}
