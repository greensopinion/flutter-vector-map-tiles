import 'dart:math';

import 'package:vector_map_tiles/src/tile_identity.dart';

class TileTranslation {
  /// the original tile
  final TileIdentity original;

  /// the tile from which the original tile data should be sourced
  final TileIdentity translated;

  /// the denominator of the fraction along a one-dimensional axis
  /// for example, one zoom level up the `fraction` would be 2.
  /// 2 levels up would be 4, etc.
  /// a `fraction` of 1 indicates that no translation is needed
  final int fraction;

  /// the offset into the translated tile, starting at 0
  final int xOffset;

  /// the offset into the translated tile, starting at 0
  final int yOffset;

  bool get isTranslated => fraction > 1;

  TileTranslation(this.original, this.translated, this.fraction, this.xOffset,
      this.yOffset);
  TileTranslation.identity(this.original)
      : this.translated = original,
        this.fraction = 1,
        this.xOffset = 0,
        this.yOffset = 0;
}

/// Translates tiles to a fragment of a tile at a lower zoom level
/// ref: https://en.wikipedia.org/wiki/Tiled_web_map
/// ref: https://wiki.openstreetmap.org/wiki/Slippy_map_tilenames
/// ref: https://developers.planet.com/tutorials/slippy-maps-101/
class SlippyMapTranslator {
  final int maxZoom;
  SlippyMapTranslator(this.maxZoom);

  TileTranslation translate(TileIdentity tile) {
    if (tile.z <= maxZoom) {
      return TileTranslation.identity(tile);
    }
    final zoomDifference = tile.z.toInt() - maxZoom;
    final divisor = pow(2, zoomDifference).toInt();
    final translatedX = tile.x ~/ divisor;
    final translatedY = tile.y ~/ divisor;
    final xOffset = (tile.x % divisor).toInt();
    final yOffset = (tile.y % divisor).toInt();
    final translated = TileIdentity(maxZoom, translatedX, translatedY);
    return TileTranslation(tile, translated, divisor, xOffset, yOffset);
  }
}
