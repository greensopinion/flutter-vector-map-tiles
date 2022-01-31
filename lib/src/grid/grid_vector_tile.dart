import 'package:flutter/material.dart' as material;
import 'package:flutter/widgets.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../options.dart';
import '../tile_identity.dart';
import 'debounce.dart';
import 'disposable_state.dart';
import 'grid_tile_positioner.dart';
import 'tile_model.dart';

class GridVectorTile extends material.StatelessWidget {
  final VectorTileModel model;

  const GridVectorTile({required Key key, required this.model})
      : super(key: key);

  @override
  material.Widget build(material.BuildContext context) {
    return GridVectorTileBody(
        key: Key('tileBody${model.tile.z}_${model.tile.x}_${model.tile.y}'),
        model: model);
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
  final VectorTileModel model;
  late final _VectorTilePainter _painter;
  _VectorTilePainter? _symbolPainter;

  _GridVectorTileBodyState(this.model);

  @override
  void initState() {
    super.initState();
    final symbolTheme = model.symbolTheme;
    _painter = _VectorTilePainter(_TileLayerOptions(model, model.theme,
        renderMode: symbolTheme != null ? RenderMode.vector : model.renderMode,
        paintBackground: model.paintBackground,
        showTileDebugInfo: model.showTileDebugInfo));
    if (symbolTheme != null) {
      _symbolPainter = _VectorTilePainter(_TileLayerOptions(model, symbolTheme,
          renderMode: RenderMode.vector,
          paintBackground: false,
          showTileDebugInfo: false));
    }
    model.addListener(() {
      if (!disposed) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    model.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tile = RepaintBoundary(
        key: Key(
            'tileBodyBoundary${widget.model.tile.z}_${widget.model.tile.x}_${widget.model.tile.y}'),
        child: CustomPaint(painter: _painter));
    final symbolPainter = _symbolPainter;
    if (symbolPainter != null) {
      return Stack(fit: StackFit.expand, children: [
        tile,
        _DelayedPainter(
            key: Key(
                'delayedSymbols${widget.model.tile.z}_${widget.model.tile.x}_${widget.model.tile.y}'),
            painter: symbolPainter)
      ]);
    }
    return tile;
  }
}

class _DelayedPainter extends material.StatefulWidget {
  final _VectorTilePainter painter;

  const _DelayedPainter({material.Key? key, required this.painter})
      : super(key: key);
  @override
  material.State<material.StatefulWidget> createState() {
    return _DelayedPainterState(painter);
  }
}

class _DelayedPainterState extends DisposableState<_DelayedPainter> {
  late final ScheduledDebounce debounce;
  final _VectorTilePainter painter;
  var _render = false;

  _DelayedPainterState(this.painter) {
    debounce = ScheduledDebounce(_notifyUpdate,
        delay: Duration(milliseconds: 800),
        jitter: Duration(milliseconds: 100),
        maxAge: Duration(seconds: 10));
    painter.options.model.addListener(() {
      debounce.update();
    });
  }

  @override
  material.Widget build(material.BuildContext context) {
    if (!_render) {
      debounce.update();
      return material.Container();
    }
    _render = false;
    return RepaintBoundary(
        key: Key(
            'tileBodyBoundarySymbols${painter.options.model.tile.z}_${painter.options.model.tile.x}_${painter.options.model.tile.y}'),
        child: CustomPaint(painter: painter));
  }

  void _notifyUpdate() {
    if (!disposed) {
      setState(() {
        _render = true;
      });
    }
  }
}

class _TileLayerOptions {
  final VectorTileModel model;
  final RenderMode renderMode;
  final Theme theme;
  final bool paintBackground;
  final bool showTileDebugInfo;

  _TileLayerOptions(this.model, this.theme,
      {required this.renderMode,
      required this.paintBackground,
      required this.showTileDebugInfo});
}

enum _PaintMode { vector, raster, background, none }

class _VectorTilePainter extends CustomPainter {
  final _TileLayerOptions options;
  TileIdentity? _lastPaintedId;
  var _lastPainted = _PaintMode.none;
  var _paintCount = 0;
  late final ScheduledDebounce debounce;

  _VectorTilePainter(this.options) : super(repaint: options.model) {
    debounce = ScheduledDebounce(_notifyIfNeeded,
        delay: Duration(milliseconds: 100),
        jitter: Duration(milliseconds: 100),
        maxAge: Duration(seconds: 10));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final model = options.model;
    if (model.disposed) {
      return;
    }
    bool changed = model.updateRendering();
    if (model.tileset == null && model.image == null) {
      if (options.paintBackground) {
        _paintBackground(canvas, size);
      }
      return;
    }
    final image = model.image;
    final renderImage = (changed ||
            model.tileset == null ||
            (options.renderMode == RenderMode.mixed &&
                (_lastPainted == _PaintMode.background ||
                    _lastPainted == _PaintMode.none))) &&
        image != null;
    final translation =
        renderImage ? model.imageTranslation : model.translation;
    if (translation == null) {
      return;
    }
    final tileSizer = GridTileSizer(translation,
        model.zoomScaleFunction(model.tile.z), size, renderImage, image);
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    tileSizer.apply(canvas);
    if (renderImage) {
      canvas.drawImage(image!, Offset.zero, Paint());
      _lastPainted = _PaintMode.raster;
      _lastPaintedId = translation.translated;
      if (options.renderMode == RenderMode.mixed) {
        debounce.update();
      }
    } else {
      final tileClip = tileSizer.tileClip(size, tileSizer.effectiveScale);
      Renderer(theme: options.theme).render(canvas, model.tileset!,
          clip: tileClip,
          zoomScaleFactor: tileSizer.effectiveScale,
          zoom: model.lastRenderedZoom);
      _lastPainted = _PaintMode.vector;
      _lastPaintedId = translation.translated;
    }
    canvas.restore();
    _paintTileDebugInfo(
        canvas, size, renderImage, tileSizer.effectiveScale, tileSizer);
  }

  void _paintBackground(Canvas canvas, Size size) {
    final model = options.model;
    final tileSizer = GridTileSizer(model.defaultTranslation,
        model.zoomScaleFunction(model.tile.z), size, false, null);
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    tileSizer.apply(canvas);
    final tileClip = tileSizer.tileClip(size, tileSizer.effectiveScale);
    Renderer(theme: options.theme).render(canvas, Tileset({}),
        clip: tileClip,
        zoomScaleFactor: tileSizer.effectiveScale,
        zoom: model.lastRenderedZoom);
    _lastPainted = _PaintMode.background;
    _lastPaintedId = null;
    canvas.restore();
    _paintTileDebugInfo(
        canvas, size, false, tileSizer.effectiveScale, tileSizer);
  }

  void _paintTileDebugInfo(Canvas canvas, Size size, bool renderedImage,
      double scale, GridTileSizer tileSizer) {
    if (options.showTileDebugInfo) {
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
      final text = TextPainter(
          text: TextSpan(
              style: textStyle,
              text:
                  '${options.model.tile}\nscale=$roundedScale\npaintCount=$_paintCount'),
          textAlign: TextAlign.start,
          textDirection: TextDirection.ltr)
        ..layout();
      text.paint(canvas, material.Offset(10, 10));
    }
  }

  void _notifyIfNeeded() {
    Future.microtask(() {
      if (_lastPainted != _PaintMode.vector) {
        options.model.requestRepaint();
      }
    });
  }

  @override
  bool shouldRepaint(covariant _VectorTilePainter oldDelegate) =>
      options.model.hasChanged() ||
      (oldDelegate._lastPainted == _PaintMode.raster &&
          (oldDelegate._lastPaintedId !=
                  options.model.imageTranslation?.translated ||
              options.model.translation != null)) ||
      (oldDelegate._lastPainted == _PaintMode.vector &&
          oldDelegate._lastPaintedId !=
              options.model.translation?.translated) ||
      (oldDelegate._lastPainted == _PaintMode.background);
}

extension RectDebugExtension on Rect {
  String debugString() => '[$left,$top,$width,$height]';
}
