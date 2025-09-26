import 'dart:math';

import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../tile_translation.dart';

class TranslationApplier {
  final double tileSize;

  TranslationApplier({required this.tileSize});

  TileData apply(TileData tileData, TileTranslation translation) {
    var transformedTileData = tileData;
    if (translation.isTranslated) {
      final clipSize = tileSize / translation.fraction;
      final paddingSize = clipSize * 0.25;
      final halfPaddingSize = paddingSize / 2;
      final totalSize = clipSize + paddingSize;
      final dx = (translation.xOffset * clipSize) - halfPaddingSize;
      final dy = (translation.yOffset * clipSize) - halfPaddingSize;
      final clip = Rectangle(dx, dy, totalSize, totalSize);
      var transformed = TileClip(bounds: clip).clip(tileData);
      if (clip.left > 0.0 || clip.top > 0.0 || translation.fraction != 1.0) {
        transformedTileData = TileTranslate(
          Point((clip.left * -1) - halfPaddingSize, (clip.top * -1) - halfPaddingSize),
          scale: translation.fraction.toDouble(),
        ).translate(transformed);
      }
    }
    return transformedTileData;
  }
}
