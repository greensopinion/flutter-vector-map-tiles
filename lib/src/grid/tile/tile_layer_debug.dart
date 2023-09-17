import 'package:flutter/material.dart';

import '../grid_tile_positioner.dart';
import 'tile_options.dart';

class TileDebugLayer extends StatelessWidget {
  final VectorTileOptions options;

  const TileDebugLayer({super.key, required this.options});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _TileDebugPainter(options));
  }
}

class _TileDebugPainter extends CustomPainter {
  final VectorTileOptions options;

  _TileDebugPainter(this.options);

  @override
  void paint(Canvas canvas, Size size) {
    final translation = options.model.translation;
    if (translation == null) {
      return;
    }
    final state = options.model.stateProvider.provide();
    final tileSizer = GridTileSizer(translation, state.zoomScale, size);
    final paint = Paint()
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..color = Colors.green;
    if (translation.zoomDifference != 0) {
      final maxZoom = options.model.tileProvider.maximumZoom;
      if (translation.translated.z != maxZoom) {
        paint.color = Colors.deepOrange;
      }
    }
    canvas.drawLine(Offset.zero, Offset(0, size.height), paint);
    canvas.drawLine(Offset.zero, Offset(size.width, 0), paint);
    final textStyle = TextStyle(
        foreground: Paint()..color = const Color.fromARGB(0xff, 0, 0, 0),
        fontSize: 15);
    final roundedScale = tileSizer.effectiveScale.toStringAsFixed(3);
    final text = TextPainter(
        text: TextSpan(
            style: textStyle,
            text:
                '${options.model.tile}\ntranslated=${translation.zoomDifference} from ${translation.translated.z}\nzoom=${state.zoom.toStringAsFixed(3)} zoomDetail=${state.zoomDetail.toStringAsFixed(3)}\nscale=$roundedScale\nsize=${size.width}\npaintCount=${options.paintCount}'),
        textAlign: TextAlign.start,
        textDirection: TextDirection.ltr)
      ..layout();
    text.paint(canvas, const Offset(10, 10));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
