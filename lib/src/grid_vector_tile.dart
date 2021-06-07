import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:vector_map_tiles/src/debounce.dart';
import 'package:vector_map_tiles/src/tile_identity.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';
import 'dart:ui' as ui;

import 'disposable_state.dart';
import 'slippy_map_translator.dart';
import 'tile_pair_cache.dart';
import 'tile_cache_key.dart';

typedef ZoomScaleFunction = double Function();
typedef ZoomFunction = double Function();

class GridVectorTile extends StatefulWidget {
  final TileIdentity tileIdentity;
  final TilePairCache cache;
  final Theme theme;
  final ZoomScaleFunction zoomScaleFunction;
  final ZoomFunction zoomFunction;

  const GridVectorTile(
      {required Key key,
      required this.tileIdentity,
      required this.cache,
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
  late final VectorTile vector;
  late final ui.Image? image;
  final TileTranslation translation;
  final ZoomScaleFunction zoomScaleFunction;
  final ZoomFunction zoomFunction;
  final Theme theme;
  double lastRenderedZoom = double.negativeInfinity;
  double lastRenderedZoomScale = double.negativeInfinity;

  VectorTileModel(TilePair tile, this.translation, this.zoomScaleFunction,
      this.zoomFunction, this.theme) {
    vector = tile.vector;
    image = tile.image?.clone();
  }

  bool updateRendering() {
    final lastRenderedZoom = zoomFunction();
    final lastRenderedZoomScale = zoomScaleFunction();
    final changed = lastRenderedZoomScale != this.lastRenderedZoomScale ||
        lastRenderedZoom != this.lastRenderedZoom;
    this.lastRenderedZoom = lastRenderedZoom;
    this.lastRenderedZoomScale = lastRenderedZoomScale;
    return changed;
  }

  void requestRepaint() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    super.dispose();
    image?.dispose();
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
  VectorTileModel? _model;

  @override
  void initState() {
    super.initState();
    final slippyMap = SlippyMapTranslator(widget.cache.provider.maximumZoom);
    var originalTranslation = slippyMap.translate(widget.tileIdentity);
    TilePair? tile = widget.cache.getValue(
        originalTranslation.toCacheKey(widget.tileIdentity.z.toInt()));
    bool loadTile = tile == null;
    if (tile == null) {
      final alternative = _findAlternative(slippyMap, originalTranslation);
      if (alternative != null) {
        _updateTileState(alternative.tile, alternative.translation);
      }
    } else {
      _updateTileState(tile, originalTranslation);
    }
    if (loadTile) {
      widget.cache
          .retrieveTile(
              originalTranslation.toCacheKey(widget.tileIdentity.z.toInt()))
          .then((tile) {
        _updateTileState(tile, originalTranslation);
      }).onError((error, stackTrace) {
        print(error);
        print(stackTrace);
      });
    }
  }

  void _updateTileState(TilePair tile, TileTranslation translation) async {
    if (!disposed) {
      VectorTileModel model = VectorTileModel(tile, translation,
          widget.zoomScaleFunction, widget.zoomFunction, widget.theme);
      setState(() {
        _model?.dispose();
        _model = model;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_model == null) {
      return Container();
    }
    return RepaintBoundary(
        child: CustomPaint(painter: _VectorTilePainter(_model!)));
  }

  @override
  void dispose() {
    super.dispose();
    _model?.dispose();
    _model = null;
  }

  _AlternativeTile? _findAlternative(
      SlippyMapTranslator slippyMap, TileTranslation originalTranslation) {
    int difference = widget.tileIdentity.z.toInt() -
        originalTranslation.translated.z.toInt() +
        1;
    final translation =
        slippyMap.lowerZoomAlternative(widget.tileIdentity, difference);
    final alternativeKey = TilePairCacheKey(translation.translated.toCacheKey(),
        translation.translated.z.toInt(), 1.0);
    final vectorTile = widget.cache.getValue(alternativeKey);
    if (vectorTile != null) {
      return _AlternativeTile(translation, vectorTile);
    }
  }
}

class _AlternativeTile {
  final TileTranslation translation;
  final TilePair tile;

  _AlternativeTile(this.translation, this.tile);
}

class _VectorTilePainter extends CustomPainter {
  final VectorTileModel model;
  late final ScheduledDebounce debounce;

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
    if (changed) {
      final image = model.image;
      if (image != null) {
        renderVector = false;
        canvas.scale(1 / _scale.toDouble());
        canvas.drawImage(image, Offset.zero, Paint());
        debounce.update();
      }
    }
    if (renderVector) {
      Renderer(theme: model.theme).render(canvas, model.vector,
          zoomScaleFactor: model.translation.fraction.toDouble() * scale,
          zoom: model.lastRenderedZoom);
    }
    canvas.restore();
  }

  void _notify() {
    Future.microtask(() {
      model.requestRepaint();
    });
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

extension _TileTranslationExtension on TileTranslation {
  TilePairCacheKey toCacheKey(int zoom, {int? specifiedFraction}) =>
      TilePairCacheKey(translated.toCacheKey(), zoom,
          (specifiedFraction ?? fraction).toDouble());
}

int _scale = 3;
