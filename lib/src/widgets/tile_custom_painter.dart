import 'package:flutter/widgets.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../layout/tile_position.dart';
import '../model/map_properties.dart';
import '../model/tile_data_model.dart';

class TileCustomPainter extends CustomPainter {
  final MapProperties mapProperties;
  final TileDataModel model;
  TilePosition? _lastPosition;

  TileCustomPainter({required this.mapProperties, required this.model});

  @override
  void paint(Canvas canvas, Size size) {
    _lastPosition = model.tilePosition;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    final scale = size.width / 256.0;
    canvas.scale(scale);
    Renderer(theme: mapProperties.theme).render(
      canvas,
      TileSource(
        tileset: model.tileset!,
        rasterTileset: model.rasterTileset ?? const RasterTileset(tiles: {}),
      ),
      rotation: 0.0,
      zoomScaleFactor: scale,
      zoom: model.tile.z.toDouble(),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant TileCustomPainter oldDelegate) =>
      _lastPosition?.position.size != oldDelegate._lastPosition?.position.size;
}
