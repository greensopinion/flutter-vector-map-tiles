import 'package:flutter/widgets.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../grid_tile_positioner.dart';
import '../tile_layer_model.dart';

class TileLayerPainter extends CustomPainter {
  final TileLayerModel model;

  TileLayerPainter(this.model) : super(repaint: model);

  @override
  void paint(Canvas canvas, Size size) {
    final zoom = model.updateRendering();
    final tileset = model.tileset;
    final translation = model.translation;
    if (tileset == null || translation == null || !model.visible) {
      return;
    }

    canvas.save();
    canvas.clipRect(Offset.zero & size);
    final tileSizer = GridTileSizer(translation, zoom.zoomScale, size);
    tileSizer.apply(canvas);

    final tileClip = tileSizer.tileClip(size, tileSizer.effectiveScale);
    Renderer(theme: model.theme).render(
        canvas,
        TileSource(
            tileset: model.tileset!,
            spriteAtlas: model.spriteImage,
            spriteIndex: model.sprites?.index),
        clip: tileClip,
        zoomScaleFactor: tileSizer.effectiveScale,
        zoom: zoom.zoom);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant TileLayerPainter oldDelegate) =>
      model.hasChanged();
}
