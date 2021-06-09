import 'package:flutter/widgets.dart';
import 'package:vector_map_tiles/src/debounce.dart';
import 'package:vector_map_tiles/src/tile_identity.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';
import 'dart:ui' as ui;

import 'disposable_state.dart';
import 'slippy_map_translator.dart';
import 'cache/caches.dart';

typedef ZoomScaleFunction = double Function();
typedef ZoomFunction = double Function();

class GridVectorTile extends StatefulWidget {
  final TileIdentity tileIdentity;
  final Caches caches;
  final Theme theme;
  final ZoomScaleFunction zoomScaleFunction;
  final ZoomFunction zoomFunction;

  const GridVectorTile(
      {required Key key,
      required this.tileIdentity,
      required this.caches,
      required this.zoomScaleFunction,
      required this.zoomFunction,
      required this.theme})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _GridVectorTile();
  }
}

class VectorTileModel extends ChangeNotifier {
  bool _disposed = false;
  bool get disposed => _disposed;

  final TileIdentity tile;
  final Theme theme;
  final Caches caches;
  final ZoomScaleFunction zoomScaleFunction;
  final ZoomFunction zoomFunction;
  double lastRenderedZoom = double.negativeInfinity;
  double lastRenderedZoomScale = double.negativeInfinity;
  late final TileTranslation translation;
  VectorTile? vector;
  ui.Image? image;

  VectorTileModel(this.caches, this.theme, this.tile, this.zoomScaleFunction,
      this.zoomFunction) {
    final slippyMap = SlippyMapTranslator(caches.vectorTileCache.maximumZoom);
    translation = slippyMap.translate(tile);
  }

  void startLoading() async {
    vector = await caches.vectorTileCache.retrieve(translation.translated);
    if (!_disposed) {
      var image = await caches.imageTileCache.getIfPresent(
          translation.translated, vector!,
          zoom: tile.z.toDouble());
      if (_disposed) {
        image?.dispose();
        return;
      } else {
        this.image = image;
      }
      notifyListeners();
      if (this.image == null) {
        var image = await caches.imageTileCache
            .retrieve(translation.translated, vector!, zoom: tile.z.toDouble());
        if (_disposed) {
          image.dispose();
          return;
        } else {
          this.image?.dispose();
          this.image = image;
        }
        notifyListeners();
      }
    }
  }

  bool updateRendering() {
    final changed = hasChanged();
    if (changed) {
      lastRenderedZoom = zoomFunction();
      lastRenderedZoomScale = zoomScaleFunction();
    }
    return changed;
  }

  bool hasChanged() {
    final lastRenderedZoom = zoomFunction();
    final lastRenderedZoomScale = zoomScaleFunction();
    return lastRenderedZoomScale != this.lastRenderedZoomScale ||
        lastRenderedZoom != this.lastRenderedZoom;
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
    super.dispose();
    image?.dispose();
    image = null;
    _disposed = true;
  }

  @override
  void removeListener(ui.VoidCallback listener) {
    if (!_disposed) {
      super.removeListener(listener);
    }
  }
}

class _GridVectorTile extends DisposableState<GridVectorTile> {
  late final VectorTileModel _model;
  late final _VectorTilePainter _painter;

  @override
  void initState() {
    super.initState();
    _model = VectorTileModel(widget.caches, widget.theme, widget.tileIdentity,
        widget.zoomScaleFunction, widget.zoomFunction);
    _model.startLoading();
    _painter = _VectorTilePainter(_model);
    _model.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_model.image == null && _model.vector == null) {
      return Container();
    }
    return RepaintBoundary(child: CustomPaint(painter: _painter));
  }

  @override
  void dispose() {
    super.dispose();
    _model.dispose();
  }
}

enum _PaintMode { vector, raster, none }

class _VectorTilePainter extends CustomPainter {
  final VectorTileModel model;
  late final ScheduledDebounce debounce;
  var _lastPainted = _PaintMode.none;

  _VectorTilePainter(VectorTileModel model)
      : this.model = model,
        super(repaint: model) {
    debounce = ScheduledDebounce(
        _notify, Duration(milliseconds: 200), Duration(seconds: 10));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final scale = model.zoomScaleFunction();
    canvas.save();
    if (model.translation.isTranslated) {
      final dx = -(model.translation.xOffset * size.width);
      final dy = -(model.translation.yOffset * size.height);
      canvas.translate(dx, dy);
      canvas.scale(model.translation.fraction.toDouble());
    }
    if (scale != 1.0) {
      canvas.scale(scale);
    }
    bool changed = model.updateRendering();
    bool renderVector = true;
    if (changed || model.vector == null) {
      final image = model.image;
      if (image != null) {
        renderVector = false;
        canvas.scale(_tileSize / image.height.toDouble());
        canvas.drawImage(image, Offset.zero, Paint());
        _lastPainted = _PaintMode.raster;
        debounce.update();
      }
    }
    if (renderVector) {
      Renderer(theme: model.theme).render(canvas, model.vector!,
          zoomScaleFactor: model.translation.fraction.toDouble() * scale,
          zoom: model.lastRenderedZoom);
      _lastPainted = _PaintMode.vector;
    }
    canvas.restore();
  }

  void _notify() {
    Future.microtask(() {
      model.requestRepaint();
    });
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) =>
      model.hasChanged() || _lastPainted != _PaintMode.vector;
}

final _tileSize = 256.0;
