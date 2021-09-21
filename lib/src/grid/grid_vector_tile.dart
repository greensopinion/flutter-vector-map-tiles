import 'package:flutter/material.dart' as material;
import 'package:flutter/widgets.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../cache/caches.dart';
import '../options.dart';
import '../tile_identity.dart';
import 'debounce.dart';
import 'disposable_state.dart';
import 'grid_tile_positioner.dart';
import 'tile_model.dart';

class GridVectorTile extends StatefulWidget {
  final TileIdentity tileIdentity;
  final RenderMode renderMode;
  final Caches caches;
  final Theme theme;
  final ZoomScaleFunction zoomScaleFunction;
  final ZoomFunction zoomFunction;
  final bool showTileDebugInfo;

  const GridVectorTile(
      {required Key key,
      required this.tileIdentity,
      required this.renderMode,
      required this.caches,
      required this.zoomScaleFunction,
      required this.zoomFunction,
      required this.theme,
      required this.showTileDebugInfo})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _GridVectorTile();
  }
}

class _GridVectorTile extends DisposableState<GridVectorTile>
    with material.SingleTickerProviderStateMixin {
  late final VectorTileModel _model;

  @override
  void initState() {
    super.initState();
    _model = VectorTileModel(
        widget.renderMode,
        widget.caches,
        widget.theme,
        widget.tileIdentity,
        widget.zoomScaleFunction,
        widget.zoomFunction,
        widget.showTileDebugInfo);
    _model.startLoading();
  }

  @override
  Widget build(BuildContext context) {
    return GridVectorTileBody(
        key: Key(
            'tileBody${widget.tileIdentity.z}_${widget.tileIdentity.x}_${widget.tileIdentity.y}'),
        model: _model);
  }

  @override
  void dispose() {
    super.dispose();
    _model.dispose();
  }
}

class GridVectorTileBody extends StatefulWidget {
  final VectorTileModel model;

  const GridVectorTileBody({required Key key, required this.model})
      : super(key: key);
  @override
  material.State<material.StatefulWidget> createState() {
    return _GridVectorTileBodyState(model);
  }
}

class _GridVectorTileBodyState extends DisposableState<GridVectorTileBody> {
  final VectorTileModel _model;
  late final _VectorTilePainter _painter;

  _GridVectorTileBodyState(this._model);

  @override
  void initState() {
    super.initState();
    _painter = _VectorTilePainter(_model);
    _model.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
        key: Key(
            'tileBodyBoundary${widget.model.tile.z}_${widget.model.tile.x}_${widget.model.tile.y}'),
        child: CustomPaint(painter: _painter));
  }
}

enum _PaintMode { vector, raster, none }

class _VectorTilePainter extends CustomPainter {
  final VectorTileModel model;
  late final ScheduledDebounce debounce;
  var _lastPainted = _PaintMode.none;
  var _paintCount = 0;

  _VectorTilePainter(VectorTileModel model)
      : this.model = model,
        super(repaint: model) {
    debounce = ScheduledDebounce(_notifyIfNeeded,
        delay: Duration(milliseconds: 200),
        jitter: Duration(milliseconds: 100),
        maxAge: Duration(seconds: 10));
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (model.image == null && model.vector == null) {
      return;
    }
    bool changed = model.updateRendering();
    final image = model.image;
    final renderImage = (changed || model.vector == null) && image != null;
    final translation =
        renderImage ? model.imageTranslation : model.translation;
    final tileSizer = GridTileSizer(
        translation, model.zoomScaleFunction(), size, renderImage, image);
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    tileSizer.apply(canvas);
    if (renderImage) {
      canvas.drawImage(image!, Offset.zero, Paint());
      _lastPainted = _PaintMode.raster;
      if (model.renderMode == RenderMode.mixed) {
        debounce.update();
      }
    } else {
      final tileClip = tileSizer.tileClip(size, tileSizer.effectiveScale);
      Renderer(theme: model.theme).render(canvas, model.vector!,
          clip: tileClip,
          zoomScaleFactor: tileSizer.effectiveScale,
          zoom: model.lastRenderedZoom);
      _lastPainted = _PaintMode.vector;
    }
    canvas.restore();
    _paintTileDebugInfo(
        canvas, size, renderImage, tileSizer.effectiveScale, tileSizer);
  }

  void _paintTileDebugInfo(Canvas canvas, Size size, bool renderedImage,
      double scale, GridTileSizer tileSizer) {
    if (model.showTileDebugInfo) {
      ++_paintCount;
      final paint = Paint()
        ..strokeWidth = 2.0
        ..style = material.PaintingStyle.stroke
        ..color = renderedImage
            ? Color.fromARGB(0xff, 0xff, 0, 0)
            : Color.fromARGB(0xff, 0, 0xff, 0);
      canvas.drawLine(Offset.zero, material.Offset(0, size.height), paint);
      canvas.drawLine(Offset.zero, material.Offset(size.width, 0), paint);
      final textStyle = TextStyle(
          foreground: Paint()..color = Color.fromARGB(0xff, 0, 0, 0),
          fontSize: 15);
      final roundedScale = (scale * 1000).roundToDouble() / 1000;
      final renderedOffset = Offset(
          -tileSizer.translationDelta.dx, -tileSizer.translationDelta.dy);
      final renderedBox = renderedOffset & size;
      final tileBox = tileSizer.tileClip(size, scale);
      final text = TextPainter(
          text: TextSpan(
              style: textStyle,
              text:
                  '${model.tile}\nscale=$roundedScale\nsize=$size\ntranslation=${tileSizer.translationDelta}\nbox=${renderedBox.debugString()}\ntileBox=${tileBox.debugString()}\npaintCount=$_paintCount'),
          textAlign: TextAlign.start,
          textDirection: TextDirection.ltr)
        ..layout();
      text.paint(canvas, material.Offset(10, 10));
    }
  }

  void _notifyIfNeeded() {
    Future.microtask(() {
      if (_lastPainted != _PaintMode.vector) {
        model.requestRepaint();
      }
    });
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) =>
      model.hasChanged() ||
      (_lastPainted == _PaintMode.none) ||
      (_lastPainted != _PaintMode.vector &&
          model.renderMode != RenderMode.raster);
}

extension RectDebugExtension on Rect {
  String debugString() => '[$left,$top,$width,$height]';
}
