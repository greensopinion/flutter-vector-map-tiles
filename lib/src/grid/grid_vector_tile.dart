import 'package:flutter/material.dart' as material;
import 'package:flutter/widgets.dart';
import 'package:vector_map_tiles/src/grid/debounce.dart';
import 'package:vector_map_tiles/src/tile_identity.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import 'disposable_state.dart';
import '../cache/caches.dart';
import 'tile_model.dart';

class GridVectorTile extends StatefulWidget {
  final TileIdentity tileIdentity;
  final Caches caches;
  final Theme theme;
  final ZoomScaleFunction zoomScaleFunction;
  final ZoomFunction zoomFunction;

  const GridVectorTile(
      {required Key key,
      required this.tileIdentity,
      required this.caches,
      required this.zoomScaleFunction,
      required this.zoomFunction,
      required this.theme})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _GridVectorTile();
  }
}

class _GridVectorTile extends DisposableState<GridVectorTile>
    with material.SingleTickerProviderStateMixin {
  late final VectorTileModel _model;

  @override
  void initState() {
    super.initState();
    _model = VectorTileModel(widget.caches, widget.theme, widget.tileIdentity,
        widget.zoomScaleFunction, widget.zoomFunction);
    _model.startLoading();
  }

  @override
  Widget build(BuildContext context) {
    return GridVectorTileBody(
        key: Key(
            'tileBody${widget.tileIdentity.z}_${widget.tileIdentity.x}_${widget.tileIdentity.y}'),
        model: _model);
  }

  @override
  void dispose() {
    super.dispose();
    _model.dispose();
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
  final VectorTileModel _model;
  late final _VectorTilePainter _painter;

  _GridVectorTileBodyState(this._model);

  @override
  void initState() {
    super.initState();
    _painter = _VectorTilePainter(_model);
    _model.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(child: CustomPaint(painter: _painter));
  }
}

enum _PaintMode { vector, raster, none }

class _VectorTilePainter extends CustomPainter {
  final VectorTileModel model;
  late final ScheduledDebounce debounce;
  var _lastPainted = _PaintMode.none;

  _VectorTilePainter(VectorTileModel model)
      : this.model = model,
        super(repaint: model) {
    debounce = ScheduledDebounce(
        _notify, Duration(milliseconds: 200), Duration(seconds: 10));
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (model.image == null && model.vector == null) {
      return;
    }
    bool changed = model.updateRendering();
    final image = model.image;
    final renderImage = (changed || model.vector == null) && image != null;
    final translation =
        renderImage ? model.imageTranslation : model.translation;

    final scale = model.zoomScaleFunction();
    canvas.save();
    if (translation.isTranslated) {
      final dx = -(translation.xOffset * size.width);
      final dy = -(translation.yOffset * size.height);
      canvas.translate(dx, dy);
      canvas.scale(translation.fraction.toDouble());
    }
    if (scale != 1.0) {
      canvas.scale(scale);
    }
    if (renderImage) {
      canvas.scale(_tileSize / image!.height.toDouble());
      canvas.drawImage(image, Offset.zero, Paint());
      _lastPainted = _PaintMode.raster;
      debounce.update();
    } else {
      Renderer(theme: model.theme).render(canvas, model.vector!,
          zoomScaleFactor: translation.fraction.toDouble() * scale,
          zoom: model.lastRenderedZoom);
      _lastPainted = _PaintMode.vector;
    }
    canvas.restore();
  }

  void _notify() {
    Future.microtask(() {
      model.requestRepaint();
    });
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) =>
      model.hasChanged() || _lastPainted != _PaintMode.vector;
}

final _tileSize = 256.0;
