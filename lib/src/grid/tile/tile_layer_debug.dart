import 'package:flutter/material.dart';
import 'tile_options.dart';

import '../grid_tile_positioner.dart';

class TileDebugLayer extends StatelessWidget {
  final VectorTileOptions options;

  const TileDebugLayer({Key? key, required this.options}) : super(key: key);

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
    final zoom = options.model.zoomProvider.provide();
    final tileSizer = GridTileSizer(translation, zoom.zoomScale, size);
    final paint = Paint()
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..color = const Color.fromARGB(0xff, 0, 0xff, 0);
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
                '${options.model.tile}\nzoom=${zoom.zoom.toStringAsFixed(3)} zoomDetail=${zoom.zoomDetail.toStringAsFixed(3)}\nscale=$roundedScale\npaintCount=${options.paintCount}'),
        textAlign: TextAlign.start,
        textDirection: TextDirection.ltr)
      ..layout();
    text.paint(canvas, const Offset(10, 10));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
