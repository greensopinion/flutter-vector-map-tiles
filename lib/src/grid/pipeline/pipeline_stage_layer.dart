import 'package:flutter/material.dart' hide Theme;
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../../cache/text_cache.dart';
import '../../tile_identity.dart';
import '../grid_tile_positioner.dart';
import '../slippy_map_translator.dart';
import '../tile_model.dart';
import '../tile_zoom.dart';

class PipelineStageLayer extends StatefulWidget {
  final PipelineStage stage;
  final VectorTileModel model;
  final TileSource tileSource;
  final TextCache textCache;
  final ChangeNotifier notifier;

  const PipelineStageLayer(
      {required super.key,
      required this.stage,
      required this.model,
      required this.tileSource,
      required this.textCache,
      required this.notifier});
  @override
  State<StatefulWidget> createState() => _PipelineStageLayer();
}

class _PaintState {
  TileState tileState = TileState.undefined();
  TileTranslation tileTranslation =
      TileTranslation.identity(TileIdentity(0, 0, 0));
}

class _PipelineStageLayer extends State<PipelineStageLayer> {
  final _paintState = _PaintState();

  @override
  void initState() {
    super.initState();
    widget.notifier.addListener(_changed);
  }

  @override
  void dispose() {
    super.dispose();
    widget.notifier.removeListener(_changed);
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
        key: Key('tile-boundary-${widget.model.tile.key()}-${widget.stage.id}'),
        child: CustomPaint(
            key:
                Key('tile-paint-${widget.model.tile.key()}-${widget.stage.id}'),
            painter: _PipelineStagePainter(layer: widget, state: _paintState),
            isComplex: true,
            willChange: false));
  }

  void _changed() {
    if (_paintState.tileTranslation != widget.model.translation ||
        widget.stage.layerTypes.contains(ThemeLayerType.symbol)) {
      setState(() {});
    }
  }
}

class _PipelineStagePainter extends CustomPainter {
  final PipelineStageLayer layer;
  final _PaintState state;

  _PipelineStagePainter({required this.layer, required this.state});

  @override
  void paint(Canvas canvas, Size size) {
    if (layer.model.disposed) {
      return;
    }
    final translation =
        layer.model.translation ?? TileTranslation.identity(layer.model.tile);
    final tileState = layer.model.stateProvider.provide();
    final tileSizer = GridTileSizer(translation, tileState.zoomScale, size);
    final tileClip = tileSizer.tileClip(size, tileSizer.effectiveScale);
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    tileSizer.apply(canvas);

    layer.stage.apply(PipelineContext(
        canvas: canvas,
        tile: layer.tileSource,
        clip: tileClip,
        zoomScaleFactor: tileSizer.effectiveScale,
        zoom: tileState.zoomDetail,
        rotation: tileState.rotation,
        painterProvider: InlineCachingTextPainterProvider(
            layer.textCache, const DefaultTextPainterProvider())));

    canvas.restore();
    state.tileState = tileState;
    state.tileTranslation = translation;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) =>
      state.tileTranslation != layer.model.translation ||
      (state.tileState != layer.model.stateProvider.provide() &&
          layer.stage.layerTypes.contains(ThemeLayerType.symbol));
}
