import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:vector_map_tiles/src/grid_tile.dart';
import 'package:vector_map_tiles/src/tile_identity.dart';

class TileWidgets {
  Map<TileIdentity, Widget> _idToWidget = {};

  void update(List<TileIdentity> tiles) {
    if (tiles.isEmpty) {
      return;
    }
    Map<TileIdentity, Widget> idToWidget = {};
    tiles.forEach((tile) {
      idToWidget[tile] = _idToWidget[tile] ?? _createWidget(tile);
    });
    _idToWidget = idToWidget;
  }

  Map<TileIdentity, Widget> get all => _idToWidget;

  Widget _createWidget(TileIdentity tile) {
    return GridTile(
        key: Key('GridTile_${tile.z}_${tile.x}_${tile.y}'), tileIdentity: tile);
  }
}
