import 'package:flutter/material.dart' hide Theme;
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../debounce.dart';
import '../grid_vector_tile.dart';
import 'pipeline_stage_layer.dart';

class PipelineGridVectorTileState extends State<GridVectorTile> {
  TilePipeline? pipeline;
  late final ScheduledDebounce _debounce;
  var _disposed = false;
  List<Widget>? stageWidgets;
  var _changeNotifier = _SafeChangeNotifier();

  @override
  void initState() {
    super.initState();
    _debounce = ScheduledDebounce(_update,
        delay: const Duration(milliseconds: 200),
        jitter: const Duration(milliseconds: 50),
        maxAge: const Duration(milliseconds: 600));
    widget.model.addListener(_modelChanged);
  }

  @override
  void dispose() {
    super.dispose();
    _disposed = true;
    _changeNotifier.dispose();
    widget.model.removeListener(_modelChanged);
  }

  @override
  void didUpdateWidget(GridVectorTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.model != widget.model) {
      oldWidget.model.removeListener(_modelChanged);
      widget.model.addListener(_modelChanged);
      _modelChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tileKey = widget.model.tile.key();
    final tilePipeline = _tilePipeline();
    var children = (stageWidgets ??
            tilePipeline.stages.map((s) => _createLayer(tilePipeline.tile, s)))
        .toList();
    if (_debug) {
      children = children +
          [
            Container(
                key: Key('debugTileKey$tileKey'),
                padding: const EdgeInsets.all(1.0),
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.green.shade600)),
                child: Text(tileKey))
          ];
    }
    widget.model.updateRendering();
    return Stack(fit: StackFit.expand, children: children);
  }

  void _modelChanged() {
    if (widget.model.hasChangedWithin(
            rotationThreshold: 0.1, zoomScaleThreshold: 1.0) ||
        widget.model.hasChanged()) {
      _debounce.update();
    }
  }

  void _update() {
    if (!_disposed) {
      if (widget.model.lastRenderedTile !=
          widget.model.translation?.translated) {
        setState(() {
          pipeline = null;
          stageWidgets = null;
          _changeNotifier.dispose();
          _changeNotifier = _SafeChangeNotifier();
        });
      } else {
        _changeNotifier.notifyListeners();
      }
    }
  }

  TilePipeline _tilePipeline() {
    var current = pipeline;
    if (current == null) {
      final state = widget.model.stateProvider.provide();
      final tileset = widget.model.tileset;
      current = TilePipeline(
          theme: widget.model.theme,
          tile: TileSource(
              tileset: tileset ?? Tileset({}),
              rasterTileset: (widget.model.rasterTileset ??
                  const RasterTileset(tiles: {})),
              spriteAtlas: widget.model.spriteImage,
              spriteIndex: widget.model.sprites?.index),
          zoom: state.zoomDetail);
      pipeline = current;
    }
    return current;
  }

  Widget _createLayer(TileSource tileSource, PipelineStage stage) =>
      PipelineStageLayer(
          key: Key('tile-${widget.model.tile.key()}-${stage.id}'),
          stage: stage,
          tileSource: tileSource,
          textCache: widget.textCache,
          model: widget.model,
          notifier: _changeNotifier);
}

class _SafeChangeNotifier extends ChangeNotifier {
  bool _disposed = false;

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

const _debug = false;
