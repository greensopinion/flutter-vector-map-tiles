import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/plugin_api.dart';

import '../tile_identity.dart';
import 'constants.dart';
import 'slippy_map_translator.dart';

class GridTilePositioner {
  final int tileZoom;
  final TilePositioningState state;

  GridTilePositioner(this.tileZoom, this.state);

  Widget positionTile(TileIdentity tile, Widget tileWidget) {
    final offset = _tileOffset(tile);
    final toRightPosition =
        _tileOffset(TileIdentity(tile.z, tile.x + 1, tile.y));
    final toBottomPosition =
        _tileOffset(TileIdentity(tile.z, tile.x, tile.y + 1));
    const tileOverlap = 0.5;
    final p = Rect.fromLTRB(offset.dx, offset.dy,
        toRightPosition.dx + tileOverlap, toBottomPosition.dy + tileOverlap);
    return Positioned(
        key: Key('PositionedGridTile_${tile.z}_${tile.x}_${tile.y}'),
        top: _roundSize(offset.dy),
        left: _roundSize(offset.dx),
        width: _roundSize(p.width),
        height: _roundSize(p.height),
        child: tileWidget);
  }

  Offset _tileOffset(TileIdentity tile) {
    final tilePosition =
        ((tile.toDoublePoint().scaleBy(tileSize) - state.origin) *
                state.zoomScale) +
            state.translate;
    return Offset(tilePosition.x.toDouble(), tilePosition.y.toDouble());
  }
}

class GridTileSizer {
  late final double effectiveScale;
  late final Offset translationDelta;

  GridTileSizer(
    TileTranslation translation,
    double scale,
    Size size,
  ) {
    var translationDelta = Offset.zero;
    var effectiveScale = scale;
    if (translation.isTranslated) {
      final dx = -(translation.xOffset * size.width);
      final dy = -(translation.yOffset * size.height);
      translationDelta = Offset(dx, dy);
      effectiveScale = effectiveScale * translation.fraction.toDouble();
    }
    if (effectiveScale != 1.0) {
      final referenceDimension = tileSize.x / translation.fraction;
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
      (-translationDelta.dx / scale).abs(),
      (-translationDelta.dy / scale).abs(),
      size.width / scale,
      size.height / scale);
}

class TilePositioningState {
  final double zoomScale;
  late final CustomPoint<double> origin;
  late final CustomPoint<double> translate;

  TilePositioningState(this.zoomScale, FlutterMapState mapState, double zoom) {
    final pixelOrigin =
        mapState.getNewPixelOrigin(mapState.center, mapState.zoom).round();
    origin = mapState.project(mapState.unproject(pixelOrigin, zoom), zoom);
    translate = (origin * zoomScale) - pixelOrigin;
  }
}

double _roundSize(double dimension) {
  double factor = 1000;
  return (dimension * factor).roundToDouble() / factor;
}
