import 'dart:ui';

import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../grid/grid_tile_positioner.dart';
import '../grid/slippy_map_translator.dart';
import '../grid/tile_zoom.dart';
import '../style/style.dart';

class TileRenderer {
  final Theme theme;
  final TextPainterProvider textPainterProvider;
  final TileState tileState;
  final TileTranslation translation;
  final Tileset tileset;
  final RasterTileset? rasterTileset;
  final Image? spriteImage;
  final SpriteStyle? sprites;

  TileRenderer(
      {required this.theme,
      required this.textPainterProvider,
      required this.tileState,
      required this.translation,
      required this.tileset,
      required this.rasterTileset,
      required this.spriteImage,
      required this.sprites});

  void render(Canvas canvas, Size size) {
    final tileSizer = GridTileSizer(translation, tileState.zoomScale, size);
    canvas.clipRect(Offset.zero & size);
    tileSizer.apply(canvas);

    final tileClip = tileSizer.tileClip(size, tileSizer.effectiveScale);
    Renderer(theme: theme, painterProvider: textPainterProvider).render(
        canvas,
        TileSource(
            tileset: tileset,
            rasterTileset: (rasterTileset ?? const RasterTileset(tiles: {})),
            spriteAtlas: spriteImage,
            spriteIndex: sprites?.index),
        clip: tileClip,
        zoomScaleFactor: tileSizer.effectiveScale,
        zoom: tileState.zoomDetail,
        rotation: tileState.rotation);
  }
}
