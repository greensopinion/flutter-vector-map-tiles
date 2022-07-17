import 'dart:async';

import 'package:flutter/material.dart' as material;
import 'package:flutter/widgets.dart';
import '../cache/text_cache.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../executor/executor.dart';
import '../executor/queue_executor.dart';
import '../tile_identity.dart';
import 'debounce.dart';
import 'tile/delay_painter.dart';
import 'tile/disposable_state.dart';
import 'grid_tile_positioner.dart';
import 'tile/symbols.dart';
import 'tile_model.dart';

class GridVectorTile extends material.StatelessWidget {
  final VectorTileModel model;
  final TextCache textCache;

  const GridVectorTile(
      {required Key key, required this.model, required this.textCache})
      : super(key: key);

  @override
  material.Widget build(material.BuildContext context) {
    return GridVectorTileBody(
        key: Key('tileBody${model.tile.key()}'),
        model: model,
        textCache: textCache);
  }
}

class GridVectorTileBody extends StatefulWidget {
  final VectorTileModel model;
  final TextCache textCache;

  const GridVectorTileBody(
      {required Key key, required this.model, required this.textCache})
      : super(key: key);
  @override
  material.State<material.StatefulWidget> createState() {
    return _GridVectorTileBodyState();
  }
}

class _GridVectorTileBodyState extends DisposableState<GridVectorTileBody> {
  late final _VectorTilePainter _painter;
  _VectorTilePainter? _symbolPainter;
  SymbolsDelayPainterModel? _symbolsDelayModel;

  _GridVectorTileBodyState();

  @override
  void initState() {
    super.initState();
    final model = widget.model;
    final textCache = widget.textCache;
    final symbolTheme = model.symbolTheme;
    _painter = _VectorTilePainter(TileLayerOptions(model, model.theme,
        textCache: textCache,
        paintBackground: model.paintBackground,
        showTileDebugInfo: model.showTileDebugInfo,
        symbolsDelayPainterModel: null));
    if (symbolTheme != null) {
      _symbolsDelayModel = SymbolsDelayPainterModel(model);
      _symbolPainter = _VectorTilePainter(TileLayerOptions(model, symbolTheme,
          textCache: textCache,
          paintBackground: false,
          showTileDebugInfo: false,
          symbolsDelayPainterModel: _symbolsDelayModel));
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
    widget.model.dispose();
    _symbolsDelayModel?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tile = RepaintBoundary(
        key: Key('tileBodyBoundary${widget.model.tile.key()}'),
        child: CustomPaint(painter: _painter));
    final symbolPainter = _symbolPainter;
    if (symbolPainter != null) {
      return Stack(fit: StackFit.expand, children: [
        tile,
        DelayPainter(
            key: Key('delayedSymbols${widget.model.tile.key()}'),
            model: _symbolsDelayModel!,
            delegate: symbolPainter)
      ]);
    }
    return tile;
  }
}

class TileLayerOptions {
  final VectorTileModel model;
  final TextCache textCache;
  final Theme theme;
  final bool paintBackground;
  final bool showTileDebugInfo;
  final SymbolsDelayPainterModel? symbolsDelayPainterModel;

  TileLayerOptions(this.model, this.theme,
      {required this.paintBackground,
      required this.textCache,
      required this.showTileDebugInfo,
      required this.symbolsDelayPainterModel});
}

enum _PaintMode { vector, background, none }

class _VectorTilePainter extends CustomPainter {
  final TileLayerOptions options;
  TileIdentity? _lastPaintedId;
  var _lastPainted = _PaintMode.none;
  var _paintCount = 0;
  late final ScheduledDebounce debounce;
  final CreatedTextPainterProvider _painterProvider =
      CreatedTextPainterProvider();
  late final CachingTextPainterProvider _cachingPainterProvider;

  _VectorTilePainter(this.options) : super(repaint: options.model) {
    _cachingPainterProvider =
        CachingTextPainterProvider(options.textCache, _painterProvider);
    debounce = ScheduledDebounce(_notifyIfNeeded,
        delay: const Duration(milliseconds: 100),
        jitter: const Duration(milliseconds: 100),
        maxAge: const Duration(seconds: 10));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final model = options.model;
    if (model.disposed) {
      return;
    }
    model.updateRendering();
    if (model.tileset == null) {
      if (options.paintBackground) {
        _paintBackground(canvas, size);
      }
      return;
    }
    final translation = model.translation;
    if (translation == null) {
      return;
    }
    final tileSizer =
        GridTileSizer(translation, model.zoomScaleFunction(model.tile.z), size);
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    tileSizer.apply(canvas);

    final tileClip = tileSizer.tileClip(size, tileSizer.effectiveScale);
    Renderer(theme: options.theme, painterProvider: _cachingPainterProvider)
        .render(canvas, model.tileset!,
            clip: tileClip,
            zoomScaleFactor: tileSizer.effectiveScale,
            zoom: model.lastRenderedZoomDetail);
    _lastPainted = _PaintMode.vector;
    _lastPaintedId = translation.translated;

    canvas.restore();
    _paintTileDebugInfo(canvas, size, tileSizer.effectiveScale, tileClip,
        model.lastRenderedZoom, model.lastRenderedZoomDetail);
    model.rendered();
    _maybeUpdateLabels();
  }

  void _paintBackground(Canvas canvas, Size size) {
    final model = options.model;
    final tileSizer = GridTileSizer(
        model.defaultTranslation, model.zoomScaleFunction(model.tile.z), size);
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
    _paintTileDebugInfo(canvas, size, tileSizer.effectiveScale, tileClip,
        model.lastRenderedZoom, model.lastRenderedZoomDetail);
  }

  void _paintTileDebugInfo(Canvas canvas, Size size, double scale, Rect clip,
      double zoom, double zoomDetail) {
    if (options.showTileDebugInfo) {
      ++_paintCount;
      final paint = Paint()
        ..strokeWidth = 2.0
        ..style = material.PaintingStyle.stroke
        ..color = const Color.fromARGB(0xff, 0, 0xff, 0);
      canvas.drawLine(Offset.zero, material.Offset(0, size.height), paint);
      canvas.drawLine(Offset.zero, material.Offset(size.width, 0), paint);
      final textStyle = TextStyle(
          foreground: Paint()..color = const Color.fromARGB(0xff, 0, 0, 0),
          fontSize: 15);
      final roundedScale = (scale * 1000).roundToDouble() / 1000;
      final text = TextPainter(
          text: TextSpan(
              style: textStyle,
              text:
                  '${options.model.tile} zoom=$zoom zoomDetail=$zoomDetail\nscale=$roundedScale clipXY=${clip.topLeft} clipSize=${clip.width} \npaintCount=$_paintCount'),
          textAlign: TextAlign.start,
          textDirection: TextDirection.ltr)
        ..layout();
      text.paint(canvas, const material.Offset(10, 10));
    }
  }

  void _notifyIfNeeded() {
    Future.microtask(() {
      if (_lastPainted != _PaintMode.vector) {
        options.model.requestRepaint();
      }
    });
  }

  void _maybeUpdateLabels() {
    if (_lastPainted == _PaintMode.vector) {
      bool hasUnpaintedSymbols =
          _painterProvider.symbolsWithoutPainter().isNotEmpty;
      if (hasUnpaintedSymbols) {
        labelUpdateExecutor
            .submit(
                UpdateTileLabelsJob(options, _painterProvider).toExecutorJob())
            .swallowCancellation();
      } else {
        options.model.symbolState.symbolsReady = true;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _VectorTilePainter oldDelegate) =>
      options.model.hasChanged() ||
      (oldDelegate._lastPainted == _PaintMode.vector &&
          oldDelegate._lastPaintedId !=
              options.model.translation?.translated) ||
      (oldDelegate._lastPainted == _PaintMode.background);
}

extension RectDebugExtension on Rect {
  String debugString() => '[$left,$top,$width,$height]';
}
