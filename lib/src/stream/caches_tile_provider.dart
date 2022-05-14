import 'dart:async';

import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../cache/caches.dart';
import 'tile_supplier.dart';
import 'tileset_executor_preprocessor.dart';

class CachesTileProvider extends TileProvider {
  final Caches _caches;
  final TilesetExecutorPreprocessor _preprocessor;

  CachesTileProvider(this._caches, this._preprocessor);

  @override
  int get maximumZoom => _caches.vectorTileCache.maximumZoom;

  @override
  Future<TileResponse> provide(TileRequest request) async {
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
    return TileResponse(identity: request.tileId, tileset: tileset);
  }
}
