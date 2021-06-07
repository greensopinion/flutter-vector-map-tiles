import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import 'abstract_loading_cache.dart';
import 'tile_cache_key.dart';

class VectorTiles extends AbstractLoadingCache<TileCacheKey, VectorTile> {
  final VectorTileProvider provider;
  VectorTiles(VectorTileProvider provider)
      : this.provider = provider,
        super(_VectorTileLoader(provider), 50);
}

class _VectorTileLoader extends Loader<TileCacheKey, VectorTile> {
  final VectorTileProvider _provider;
  _VectorTileLoader(this._provider);

  @override
  Future<VectorTile> load(TileCacheKey key) {
    final tile = TileIdentity(key.z, key.x, key.y);
    if (key.x < 0 || key.y < 0 || key.z > _provider.maximumZoom) {
      return Future.error('tile out of range: $key');
    }
    return _provider
        .provide(tile)
        .then((bytes) => VectorTileReader().read(bytes));
  }
}
