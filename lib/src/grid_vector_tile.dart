import 'package:flutter/widgets.dart';
import 'package:vector_map_tiles/src/tile_identity.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import 'disposable_state.dart';
import 'slippy_map_translator.dart';
import 'vector_tile_provider.dart';

typedef ZoomScaleFunction = double Function();

class GridVectorTile extends StatefulWidget {
  final TileIdentity tileIdentity;
  final VectorTileProvider tileProvider;
  final Theme theme;
  final ZoomScaleFunction zoomScaleFunction;

  const GridVectorTile(
      {required Key key,
      required this.tileIdentity,
      required this.tileProvider,
      required this.zoomScaleFunction,
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
    _translation = SlippyMapTranslator(widget.tileProvider.maximumZoom)
        .translate(widget.tileIdentity);
    widget.tileProvider.provide(_translation.translated).then((bytes) {
      if (!disposed) {
        setState(() {
          this._tile = VectorTileReader().read(bytes);
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
        painter: _VectorTilePainter(
            _translation, _tile!, widget.zoomScaleFunction, widget.theme));
  }
}

class _VectorTilePainter extends CustomPainter {
  final TileTranslation _translation;
  final VectorTile _tile;
  final ZoomScaleFunction _zoomScaleFunction;
  final Theme _theme;

  _VectorTilePainter(
      this._translation, this._tile, this._zoomScaleFunction, this._theme);

  @override
  void paint(Canvas canvas, Size size) {
    double scale = _zoomScaleFunction();
    canvas.save();
    if (_translation.isTranslated) {
      double dx = -(_translation.xOffset * size.width);
      double dy = -(_translation.yOffset * size.height);
      canvas.translate(dx, dy);
      canvas.scale(_translation.fraction.toDouble());
    }
    if (scale != 1.0) {
      canvas.scale(scale);
    }
    Renderer(theme: _theme)
        .render(canvas, _tile, zoom: _translation.original.z.toInt());

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
