import 'dart:async';

import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../cache/caches.dart';
import '../cache/memory_image_cache.dart';
import 'tile_supplier.dart';
import 'tileset_executor_preprocessor.dart';

class CachesTileProvider extends TileProvider {
  final Caches _caches;
  final TilesetExecutorPreprocessor _preprocessor;

  CachesTileProvider(this._caches, this._preprocessor);

  @override
  int get maximumZoom => _caches.vectorTileCache.maximumZoom;

  @override
  Future<TileResponse> provide(TileProviderRequest request) async {
    if (request.format == TileFormat.vector) {
      Map<String, Future<Tile>> futureBySource = {};
      for (final source in _caches.providerSources) {
        futureBySource[source] = _caches.vectorTileCache
            .retrieve(source, request.tileId, cancelled: request.cancelled);
      }
      Map<String, Tile> tileBySource = {};
      for (final entry in futureBySource.entries) {
        request.testCancelled();
        tileBySource[entry.key] = await entry.value;
      }
      final tileset = await _preprocessor.preprocess(request.tileId,
          Tileset(tileBySource), request.zoom.truncate(), request.cancelled);
      return TileResponse(
          identity: request.tileId, format: request.format, tileset: tileset);
    } else {
      final effectiveZoom = request.zoom.ceil();
      final imageKey = ImageKey(request.tileId, effectiveZoom);
      final image = _caches.memoryImageCache.get(imageKey);
      if (image != null) {
        return TileResponse(
            identity: request.tileId,
            format: TileFormat.raster,
            tileset: null,
            image: image);
      }
      final tile = await provide(TileProviderRequest(
          tileId: request.tileId,
          format: TileFormat.vector,
          zoom: request.zoom,
          cancelled: request.cancelled));
      request.testCancelled();
      final loaded = await _caches.imageTileCache.retrieve(
          tile.identity, tile.tileset!,
          zoom: effectiveZoom, cancelled: request.cancelled);
      _caches.memoryImageCache.put(imageKey, loaded);
      return TileResponse(
          identity: tile.identity,
          format: TileFormat.raster,
          tileset: null,
          image: loaded);
    }
  }
}
