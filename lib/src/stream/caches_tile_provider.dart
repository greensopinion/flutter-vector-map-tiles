import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../cache/caches.dart';
import '../cache/memory_image_cache.dart';
import '../provider_exception.dart';
import '../tile_identity.dart';
import 'tile_supplier.dart';

class CachesTileProvider extends TileProvider {
  final Caches _caches;

  CachesTileProvider(
    this._caches,
  );

  @override
  int get maximumZoom => _caches.vectorTileCache.maximumZoom;

  @override
  Future<Tile> provide(TileIdentity tileIdentity, TileFormat format,
      {double? zoom}) async {
    if (format == TileFormat.vector) {
      Map<String, Future<VectorTile>> futureBySource = {};
      for (final source in _caches.providerSources) {
        futureBySource[source] =
            _caches.vectorTileCache.retrieve(source, tileIdentity);
      }
      Map<String, VectorTile> tileBySource = {};
      for (final entry in futureBySource.entries) {
        VectorTile? tile;
        try {
          tile = await entry.value;
        } catch (error) {
          if (error is ProviderException && error.statusCode == 404) {
            print(error);
            tile = VectorTile(layers: []);
          } else {
            rethrow;
          }
        }
        tileBySource[entry.key] = tile;
      }
      return Tile(
          identity: tileIdentity,
          format: format,
          tileset: Tileset(tileBySource));
    } else {
      final effectiveZoom = zoom == null ? tileIdentity.z : zoom.ceil();
      final imageKey = ImageKey(tileIdentity, effectiveZoom);
      final image = _caches.memoryImageCache.get(imageKey);
      if (image != null) {
        return Tile(
            identity: tileIdentity,
            format: format,
            tileset: null,
            image: image);
      }
      final tile = await provide(tileIdentity, TileFormat.vector);
      final loaded = await _caches.imageTileCache
          .retrieve(tile.identity, tile.tileset!, zoom: effectiveZoom);
      _caches.memoryImageCache.put(imageKey, loaded);
      return Tile(
          identity: tile.identity,
          format: format,
          tileset: null,
          image: loaded);
    }
  }
}
