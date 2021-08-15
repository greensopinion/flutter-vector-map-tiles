import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/plugin_api.dart';
import 'slippy_map_translator.dart';
import '../tile_identity.dart';
import 'dart:ui' as ui;

class GridTilePositioner {
  final TilePositioningState state;

  GridTilePositioner(this.state);

  Widget positionTile(TileIdentity tile, Widget tileWidget) {
    final offset = _tileOffset(tile);
    final toRightPosition =
        _tileOffset(TileIdentity(tile.z, tile.x + 1, tile.y));
    final toBottomPosition =
        _tileOffset(TileIdentity(tile.z, tile.x, tile.y + 1));
    final tileOverlap = 0.5;
    final p = Rect.fromLTRB(offset.dx, offset.dy,
        toRightPosition.dx + tileOverlap, toBottomPosition.dy + tileOverlap);
    final position = Rect.fromLTWH(_roundSize(offset.dx), _roundSize(offset.dy),
        _roundSize(p.width), _roundSize(p.height));
    return Positioned(
        key: Key('PositionedGridTile_${tile.z}_${tile.x}_${tile.y}'),
        top: position.top,
        left: position.left,
        width: position.width,
        height: position.height,
        child: tileWidget);
  }

  Offset _tileOffset(TileIdentity tile) {
    final tilePosition =
        (tile.scaleBy(tileSize) - state.origin).multiplyBy(state.zoomScale) +
            state.translate;
    return Offset(tilePosition.x.toDouble(), tilePosition.y.toDouble());
  }
}

class GridTileSizer {
  late final double effectiveScale;
  late final Offset translationDelta;

  GridTileSizer(TileTranslation translation, double scale, Size size,
      bool renderImage, ui.Image? image) {
    var translationDelta = Offset.zero;
    var effectiveScale = scale;
    if (translation.isTranslated) {
      final dx = -(translation.xOffset * size.width);
      final dy = -(translation.yOffset * size.height);
      translationDelta = Offset(dx, dy);
      effectiveScale = effectiveScale * translation.fraction.toDouble();
    }
    if (renderImage) {
      effectiveScale = effectiveScale * (_tileSize / image!.height.toDouble());
    }
    if (effectiveScale != 1.0) {
      final referenceDimension =
          (renderImage ? image!.height.toDouble() : _tileSize) /
              translation.fraction;
      final scaledSize = effectiveScale * referenceDimension;
      final maxDimension = max(size.width, size.height);
      if (scaledSize < maxDimension) {
        effectiveScale = maxDimension / referenceDimension;
      }
    }
    this.translationDelta = translationDelta;
    this.effectiveScale = effectiveScale;
  }

  void apply(Canvas canvas) {
    if (translationDelta != Offset.zero) {
      canvas.translate(translationDelta.dx, translationDelta.dy);
    }
    if (effectiveScale != 1.0) {
      canvas.scale(effectiveScale);
    }
  }

  Rect tileClip(Size size, double scale) => Rect.fromLTWH(
      -translationDelta.dx / scale,
      -translationDelta.dy / scale,
      size.width / scale,
      size.height / scale);
}

class TilePositioningState {
  final double zoomScale;
  late final CustomPoint<num> origin;
  late final CustomPoint<num> translate;

  TilePositioningState(this.zoomScale, MapState mapState) {
    final pixelOrigin =
        mapState.getNewPixelOrigin(mapState.center, mapState.zoom).round();
    origin = mapState.project(mapState.unproject(pixelOrigin), mapState.zoom);
    translate = origin.multiplyBy(zoomScale) - pixelOrigin;
  }
}

final _tileSize = 256.0;
final tileSize = CustomPoint(_tileSize, _tileSize);

double _roundSize(double dimension) {
  double factor = 1000;
  return (dimension * factor).roundToDouble() / factor;
}
