import 'package:flutter/widgets.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../../cache/text_cache.dart';
import '../../tile_identity.dart';
import '../grid_tile_positioner.dart';
import 'symbols.dart';
import 'tile_options.dart';

enum _PaintMode { vector, background, none }

class VectorTilePainter extends CustomPainter {
  final VectorTileOptions options;
  TileIdentity? _lastPaintedId;
  var _lastPainted = _PaintMode.none;
  final CreatedTextPainterProvider _painterProvider =
      CreatedTextPainterProvider();
  late final CachingTextPainterProvider _cachingPainterProvider;

  VectorTilePainter(this.options) : super(repaint: options.model) {
    _cachingPainterProvider =
        CachingTextPainterProvider(options.textCache, _painterProvider);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final model = options.model;
    if (model.disposed) {
      return;
    }
    final tileState = model.updateRendering();
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
    final tileSizer = GridTileSizer(translation, tileState.zoomScale, size);
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    tileSizer.apply(canvas);

    final tileClip = tileSizer.tileClip(size, tileSizer.effectiveScale);
    Renderer(theme: options.theme, painterProvider: _cachingPainterProvider)
        .render(
            canvas,
            TileSource(
                tileset: model.tileset!,
                rasterTileset:
                    (model.rasterTileset ?? const RasterTileset(tiles: {})),
                spriteAtlas: model.spriteImage,
                spriteIndex: model.sprites?.index),
            clip: tileClip,
            zoomScaleFactor: tileSizer.effectiveScale,
            zoom: tileState.zoomDetail,
            rotation: tileState.rotation);
    _lastPainted = _PaintMode.vector;
    _lastPaintedId = translation.translated;

    canvas.restore();
    model.rendered();
    _maybeUpdateLabels();
  }

  void _paintBackground(Canvas canvas, Size size) {
    final model = options.model;
    final tileSizer = GridTileSizer(
        model.defaultTranslation, model.lastRenderedState.zoomScale, size);
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    tileSizer.apply(canvas);
    final tileClip = tileSizer.tileClip(size, tileSizer.effectiveScale);
    Renderer(theme: options.theme).render(
        canvas, TileSource(tileset: Tileset({})),
        clip: tileClip,
        zoomScaleFactor: tileSizer.effectiveScale,
        zoom: model.lastRenderedState.zoom,
        rotation: model.lastRenderedState.rotation);
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
  bool shouldRepaint(covariant VectorTilePainter oldDelegate) =>
      options.model.hasChanged() ||
      (oldDelegate._lastPainted == _PaintMode.vector &&
          oldDelegate._lastPaintedId !=
              options.model.translation?.translated) ||
      (oldDelegate._lastPainted == _PaintMode.background);
}
