import 'package:flutter/material.dart' as material;
import 'package:flutter/widgets.dart';

import '../cache/text_cache.dart';
import 'tile/delay_painter.dart';
import 'tile/disposable_state.dart';
import 'tile/symbols.dart';
import 'tile/tile_layer_debug.dart';
import 'tile/tile_options.dart';
import 'tile/tile_painter.dart';
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
    options = VectorTileOptions(model, model.theme,
        textCache: textCache,
        paintBackground: model.paintBackground,
        symbolsDelayPainterModel: null);
    _painter = VectorTilePainter(options);
    if (symbolTheme != null) {
      _symbolsDelayModel = SymbolsDelayPainterModel(model);
      _symbolPainter = VectorTilePainter(VectorTileOptions(model, symbolTheme,
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
