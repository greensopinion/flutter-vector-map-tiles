import 'dart:developer';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import '../executor/executor.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../profiler.dart';
import '../stream/tile_supplier.dart';
import '../tile_identity.dart';
import 'slippy_map_translator.dart';

typedef ZoomScaleFunction = double Function(int tileZoom);
typedef ZoomFunction = double Function();

class VectorTileModel extends ChangeNotifier {
  bool _disposed = false;
  bool get disposed => _disposed;

  final TileIdentity tile;
  final TileProvider tileProvider;
  final Theme theme;
  final Theme? symbolTheme;
  bool paintBackground;
  final bool showTileDebugInfo;
  final ZoomScaleFunction zoomScaleFunction;
  final ZoomFunction zoomFunction;
  final ZoomFunction zoomDetailFunction;
  double lastRenderedZoom = double.negativeInfinity;
  double lastRenderedZoomDetail = double.negativeInfinity;
  double lastRenderedZoomScale = double.negativeInfinity;
  late final TileTranslation defaultTranslation;
  TileTranslation? translation;
  Tileset? tileset;
  late final TimelineTask _firstRenderedTask;
  bool _firstRendered = false;
  bool showLabels = true;
  final symbolState = VectorTileSymbolState();

  VectorTileModel(
      this.tileProvider,
      this.theme,
      this.symbolTheme,
      this.tile,
      this.zoomScaleFunction,
      this.zoomFunction,
      this.zoomDetailFunction,
      this.paintBackground,
      this.showTileDebugInfo) {
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

  void startLoading() async {
    final request = TileRequest(
        tileId: tile.normalize(),
        zoom: zoomFunction(),
        zoomDetail: zoomDetailFunction(),
        cancelled: () => _disposed);
    tileProvider.provide(request).swallowCancellation().maybeThen(_receiveTile);
  }

  void _receiveTile(TileResponse received) {
    final newTranslation = SlippyMapTranslator(tileProvider.maximumZoom)
        .specificZoomTranslation(tile, zoom: received.identity.z);
    tileset = received.tileset;
    translation = newTranslation;
    notifyListeners();
  }

  bool updateRendering() {
    final changed = hasChanged();
    if (changed) {
      lastRenderedZoom = zoomFunction();
      lastRenderedZoomDetail = zoomDetailFunction();
      lastRenderedZoomScale = zoomScaleFunction(tile.z);
    }
    return changed;
  }

  bool hasChanged() {
    final lastRenderedZoom = zoomFunction();
    final lastRenderedZoomDetail = zoomDetailFunction();
    final lastRenderedZoomScale = zoomScaleFunction(tile.z);
    return lastRenderedZoomScale != this.lastRenderedZoomScale ||
        lastRenderedZoom != this.lastRenderedZoom ||
        lastRenderedZoomDetail != this.lastRenderedZoomDetail;
  }

  void requestRepaint() {
    notifyListeners();
  }

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

      if (!_firstRendered) {
        _firstRendered = true;
        _firstRenderedTask.finish(arguments: {'cancelled': true});
      }
    }
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
