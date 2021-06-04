import 'dart:collection';

import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

class VectorTiles {
  final _map = LinkedHashMap<TileIdentity, VectorTile>();
  final _fetching = Map<TileIdentity, Future<VectorTile>>();
  final _maxSize = 200;
  final VectorTileProvider provider;

  VectorTiles(this.provider);

  Future<VectorTile> getTile(TileIdentity tile) {
    VectorTile? vectorTile = _map[tile];
    if (vectorTile == null) {
      var future = _fetching[tile];
      if (future == null) {
        future = provider.provide(tile).then((bytes) {
          VectorTile newTile = VectorTileReader().read(bytes);
          _map[tile] = newTile;
          _fetching.remove(tile);
          _applyMaxSize();
          return newTile;
        });
        _fetching[tile] = future;
      }
      return future;
    } else {
      _map.remove(tile);
      _map[tile] = vectorTile;
    }
    return Future.value(vectorTile);
  }

  void _applyMaxSize() {
    while (_map.length > _maxSize) {
      _map.remove(_map.keys.first);
    }
  }
}
