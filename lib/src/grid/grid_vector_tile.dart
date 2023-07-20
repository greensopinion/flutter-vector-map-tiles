import 'package:flutter/material.dart' as material;
import 'package:flutter/widgets.dart';

import '../cache/text_cache.dart';
import 'tile/delay_painter.dart';
import 'tile/disposable_state.dart';
import 'tile/symbols.dart';
import 'tile/tile_layer_debug.dart';
import 'tile/tile_layer_painter.dart';
import 'tile/tile_options.dart';
import 'tile/tile_painter.dart';
import 'tile_layer_model.dart';
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
  late final VectorTilePainter _painter;
  late final VectorTileOptions options;
  VectorTilePainter? _symbolPainter;
  SymbolsDelayPainterModel? _symbolsDelayModel;

  _GridVectorTileState();

  @override
  void initState() {
    super.initState();
    final model = widget.model;
    final textCache = widget.textCache;
    final symbolTheme = model.symbolTheme;
    options = VectorTileOptions(model, model.layers.first.theme,
        sprites: model.layers.first.sprites,
        textCache: textCache,
        paintBackground: model.paintBackground,
        symbolsDelayPainterModel: null);
    _painter = VectorTilePainter(options);
    if (symbolTheme != null) {
      _symbolsDelayModel = SymbolsDelayPainterModel(model);
      _symbolPainter = VectorTilePainter(VectorTileOptions(model, symbolTheme,
          sprites: model.layers.first.sprites,
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

    final children = <Widget>[tile];
    if (widget.model.layers.length > 1) {
      for (final tileLayerModel in widget.model.layers.sublist(1)) {
        children.add(_GridVectorTileLayer(
            model: tileLayerModel, key: Key('tileLayer${tileLayerModel.id}')));
      }
    }
    final symbolPainter = _symbolPainter;
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

class _GridVectorTileLayer extends material.StatefulWidget {
  final TileLayerModel model;

  const _GridVectorTileLayer({super.key, required this.model});

  @override
  material.State<material.StatefulWidget> createState() {
    return _GridVectorTileLayerState();
  }
}

class _GridVectorTileLayerState extends State<_GridVectorTileLayer> {
  late final TileLayerPainter _painter;

  @override
  void initState() {
    super.initState();
    _painter = TileLayerPainter(widget.model);
    widget.model.addListener(() {
      setState(() {});
    });
  }

  @override
  material.Widget build(material.BuildContext context) {
    return RepaintBoundary(
        key: Key('tileLayerBoundary${widget.model.id}'),
        child: CustomPaint(painter: _painter));
  }
}
