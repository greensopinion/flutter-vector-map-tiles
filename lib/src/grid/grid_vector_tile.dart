import 'package:flutter/material.dart' as material;
import 'package:flutter/widgets.dart';
import '../cache/text_cache.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../tile_identity.dart';
import 'tile/delay_painter.dart';
import 'tile/disposable_state.dart';
import 'grid_tile_positioner.dart';
import 'tile/symbols.dart';
import 'tile/tile_layer_debug.dart';
import 'tile/tile_options.dart';
import 'tile_model.dart';

class GridVectorTile extends material.StatefulWidget {
  final VectorTileModel model;
  final TextCache textCache;

  const GridVectorTile(
      {required Key key, required this.model, required this.textCache})
      : super(key: key);

  @override
  material.State<material.StatefulWidget> createState() =>
      _GridVectorTileState();
}

class _GridVectorTileState extends DisposableState<GridVectorTile> {
  late final _VectorTilePainter _painter;
  late final VectorTileOptions options;
  _VectorTilePainter? _symbolPainter;
  SymbolsDelayPainterModel? _symbolsDelayModel;

  _GridVectorTileState();

  @override
  void initState() {
    super.initState();
    final model = widget.model;
    final textCache = widget.textCache;
    final symbolTheme = model.symbolTheme;
    options = VectorTileOptions(model, model.theme,
        textCache: textCache,
        paintBackground: model.paintBackground,
        symbolsDelayPainterModel: null);
    _painter = _VectorTilePainter(options);
    if (symbolTheme != null) {
      _symbolsDelayModel = SymbolsDelayPainterModel(model);
      _symbolPainter = _VectorTilePainter(VectorTileOptions(model, symbolTheme,
          textCache: textCache,
          paintBackground: false,
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
    final tileKey = widget.model.tile.key();
    final tile = RepaintBoundary(
        key: Key('tileBodyBoundary$tileKey'),
        child: CustomPaint(painter: _painter));
    final symbolPainter = _symbolPainter;
    final children = <Widget>[tile];
    if (symbolPainter != null) {
      children.add(DelayPainter(
          key: Key('delayedSymbols${widget.model.tile.key()}'),
          model: _symbolsDelayModel!,
          delegate: symbolPainter));
    }
    if (widget.model.showTileDebugInfo) {
      children
          .add(TileDebugLayer(key: Key('tileDebug$tileKey'), options: options));
    }
    if (children.length > 1) {
      return Stack(fit: StackFit.expand, children: children);
    }
    return tile;
  }
}

enum _PaintMode { vector, background, none }

class _VectorTilePainter extends CustomPainter {
  final VectorTileOptions options;
  TileIdentity? _lastPaintedId;
  var _lastPainted = _PaintMode.none;
  final CreatedTextPainterProvider _painterProvider =
      CreatedTextPainterProvider();
  late final CachingTextPainterProvider _cachingPainterProvider;

  _VectorTilePainter(this.options) : super(repaint: options.model) {
    _cachingPainterProvider =
        CachingTextPainterProvider(options.textCache, _painterProvider);
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
    ++options.paintCount;
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
  }

  void _maybeUpdateLabels() {
    if (_lastPainted == _PaintMode.vector) {
      bool hasUnpaintedSymbols =
          _painterProvider.symbolsWithoutPainter().isNotEmpty;
      if (hasUnpaintedSymbols) {
        sheduleLabelsUpdate(options, _painterProvider);
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
