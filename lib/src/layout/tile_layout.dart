import 'dart:ui';

import '../tile_identity.dart';
import '../tile_offset.dart';
import 'map_state.dart';
import 'tile_position.dart';
import 'tile_viewport.dart';
import 'zoom_scaler.dart';

class TileLayout {
  final TileOffset offset;
  final TileViewport viewport;
  final int tileSize;

  TileLayout({
    required this.offset,
    required this.viewport,
    required this.tileSize,
  });

  List<TilePosition> computeTilePositions(
    MapState mapState,
    ZoomScaler zoomScaler,
  ) {
    final tiles = <TileIdentity>[];

    final minTileX = viewport.bounds.left.floor();
    final maxTileX = viewport.bounds.right.ceil();
    final minTileY = viewport.bounds.top.floor();
    final maxTileY = viewport.bounds.bottom.ceil();

    for (int tileX = minTileX; tileX <= maxTileX; tileX++) {
      for (int tileY = minTileY; tileY <= maxTileY; tileY++) {
        final id = TileIdentity(viewport.zoom, tileX, tileY);
        if (id.isValidWrapped()) {
          tiles.add(id);
        }
      }
    }
    return _positionTiles(mapState, zoomScaler, viewport.zoom, tiles);
  }

  TilePosition positionTile(
    MapState mapState,
    ZoomScaler zoomScaler,
    TileIdentity tile,
  ) => _positionTiles(mapState, zoomScaler, tile.z, [tile]).first;

  List<TilePosition> _positionTiles(
    MapState mapState,
    ZoomScaler zoomScaler,
    int zoom,
    List<TileIdentity> tiles,
  ) {
    final positioner = _Positioner(
      mapState: mapState,
      tileSize: tileSize,
      zoom: zoom.toDouble(),
      zoomScale: zoomScaler.tileScale(tileZoom: zoom),
    );

    final wrappedOutput = <TilePosition>[];
    final regularOutput = <TilePosition>[];

    for (final tile in tiles) {
      if (!tile.isValid()) {
        wrappedOutput.add(positioner.positionTile(tile));
      } else {
        regularOutput.add(positioner.positionTile(tile));
      }
    }

    final regularTileIdentities = regularOutput.map((p) => p.tile).toSet();
    final filteredWrapped = wrappedOutput
        .where((p) => !regularTileIdentities.contains(p.tile));

    return [...regularOutput, ...filteredWrapped];
  }
}

class _Positioner {
  final MapState mapState;
  final int tileSize;
  final double zoom;
  final double zoomScale;
  late final Offset origin;
  late final Offset translate;

  _Positioner({
    required this.mapState,
    required this.tileSize,
    required this.zoom,
    required this.zoomScale,
  }) {
    origin = mapState.pixelOrigin;
    translate = (origin * zoomScale) - origin;
  }

  TilePosition positionTile(TileIdentity tile) {
    final offset = _tileOffset(tile);
    final toRightPosition = _tileOffset(
      TileIdentity(tile.z, tile.x + 1, tile.y),
    );
    final toBottomPosition = _tileOffset(
      TileIdentity(tile.z, tile.x, tile.y + 1),
    );
    const tileOverlap = 1.0;
    final position = Rect.fromLTRB(
      offset.dx,
      offset.dy,
      toRightPosition.dx + tileOverlap,
      toBottomPosition.dy + tileOverlap,
    );
    return TilePosition(tile: tile.wrapped(), position: position);
  }

  Offset _tileOffset(TileIdentity tile) {
    final tileOffset = Offset(
      tile.x.toDouble() * tileSize,
      tile.y.toDouble() * tileSize,
    );

    return (tileOffset - origin) * zoomScale + translate;
  }
}
