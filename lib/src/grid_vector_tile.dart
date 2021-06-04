import 'package:flutter/widgets.dart';
import 'package:vector_map_tiles/src/tile_identity.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import 'disposable_state.dart';
import 'slippy_map_translator.dart';
import 'vector_tiles.dart';

typedef ZoomScaleFunction = double Function();
typedef ZoomFunction = double Function();

class GridVectorTile extends StatefulWidget {
  final TileIdentity tileIdentity;
  final VectorTiles vectorTiles;
  final Theme theme;
  final ZoomScaleFunction zoomScaleFunction;
  final ZoomFunction zoomFunction;

  const GridVectorTile(
      {required Key key,
      required this.tileIdentity,
      required this.vectorTiles,
      required this.zoomScaleFunction,
      required this.zoomFunction,
      required this.theme})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _GridVectorTile();
  }
}

class _GridVectorTile extends DisposableState<GridVectorTile> {
  VectorTile? _tile;
  late TileTranslation _translation;

  @override
  void initState() {
    super.initState();
    _translation = SlippyMapTranslator(widget.vectorTiles.provider.maximumZoom)
        .translate(widget.tileIdentity);
    widget.vectorTiles.getTile(_translation.translated).then((tile) {
      if (!disposed) {
        setState(() {
          this._tile = tile;
        });
      }
    }).onError((error, stackTrace) {
      print(error);
      print(stackTrace);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_tile == null) {
      return Container();
    }
    return CustomPaint(
        painter: _VectorTilePainter(_translation, _tile!,
            widget.zoomScaleFunction, widget.zoomFunction, widget.theme));
  }
}

class _VectorTilePainter extends CustomPainter {
  final TileTranslation _translation;
  final VectorTile _tile;
  final ZoomScaleFunction _zoomScaleFunction;
  final ZoomFunction zoomFunction;
  final Theme _theme;

  _VectorTilePainter(this._translation, this._tile, this._zoomScaleFunction,
      this.zoomFunction, this._theme);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = _zoomScaleFunction();
    canvas.save();
    if (_translation.isTranslated) {
      final dx = -(_translation.xOffset * size.width);
      final dy = -(_translation.yOffset * size.height);
      canvas.translate(dx, dy);
      canvas.scale(_translation.fraction.toDouble());
    }
    if (scale != 1.0) {
      canvas.scale(scale);
    }
    Renderer(theme: _theme).render(canvas, _tile,
        zoomScaleFactor: _translation.fraction.toDouble() * scale,
        zoom: zoomFunction());
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
