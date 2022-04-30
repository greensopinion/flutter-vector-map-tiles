import 'dart:developer';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../executor/executor.dart';
import '../options.dart';
import '../profiler.dart';
import '../stream/tile_supplier.dart';
import '../tile_identity.dart';
import 'slippy_map_translator.dart';

typedef ZoomScaleFunction = double Function(int tileZoom);
typedef ZoomFunction = double Function();

class VectorTileModel extends ChangeNotifier {
  bool _disposed = false;
  bool get disposed => _disposed;

  final RenderMode renderMode;
  final TileIdentity tile;
  final TileSupplier tileSupplier;
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
  TileTranslation? imageTranslation;
  Tileset? tileset;
  ui.Image? image;
  late final TimelineTask _firstRenderedTask;
  bool _firstRendered = false;
  bool showLabels = true;

  VectorTileModel(
      this.renderMode,
      this.tileSupplier,
      this.theme,
      this.symbolTheme,
      this.tile,
      this.zoomScaleFunction,
      this.zoomFunction,
      this.zoomDetailFunction,
      this.paintBackground,
      this.showTileDebugInfo) {
    defaultTranslation =
        SlippyMapTranslator(tileSupplier.maximumZoom).translate(tile);
    _firstRenderedTask = tileRenderingTask(tile);
  }

  bool get hasData => image != null || tileset != null;

  void rendered() {
    if (!_firstRendered) {
      _firstRendered = true;
      _firstRenderedTask.finish();
    }
  }

  void startLoading() async {
    final request = TileRequest(
        tileId: tile.normalize(),
        primaryFormat: renderMode == RenderMode.raster
            ? TileFormat.raster
            : TileFormat.vector,
        secondaryFormat:
            renderMode == RenderMode.mixed ? TileFormat.raster : null,
        zoom: zoomFunction(),
        zoomDetail: zoomDetailFunction(),
        cancelled: () => _disposed);
    final futures = tileSupplier.stream(request);
    for (final future in futures) {
      future
          .then(_receiveTile)
          .catchError(_tileError, test: (it) => it is CancellationException);
    }
  }

  void _tileError(error, stack) async {
    if (error is CancellationException) {
      // expected, ignore
    } else {
      // should never reach here, but rethrow in case
      throw error;
    }
  }

  void _receiveTile(TileResponse received) {
    final newTranslation = SlippyMapTranslator(tileSupplier.maximumZoom)
        .specificZoomTranslation(tile, zoom: received.identity.z);
    if (received.format == TileFormat.raster) {
      if (_disposed) {
        received.image?.dispose();
      } else {
        var hadImage = image != null;
        image?.dispose();
        image = received.image;
        imageTranslation = newTranslation;
        if (hadImage && renderMode != RenderMode.raster) {
          Future.delayed(Duration(milliseconds: 300)).then((value) {
            if (tileset == null && imageTranslation == newTranslation) {
              notifyListeners();
            }
          });
        } else if (tileset == null) {
          notifyListeners();
        }
      }
    } else {
      tileset = received.tileset;
      translation = newTranslation;
      notifyListeners();
    }
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
      image?.dispose();
      image = null;
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
