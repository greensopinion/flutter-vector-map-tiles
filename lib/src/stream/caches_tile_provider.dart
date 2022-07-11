import 'dart:async';

import 'package:vector_map_tiles/src/stream/tile_processor.dart';
import 'package:vector_map_tiles/src/stream/tileset_ui_preprocessor.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../cache/caches.dart';
import 'tile_supplier.dart';
import 'tileset_executor_preprocessor.dart';

class CachesTileProvider extends TileProvider {
  final Caches _caches;
  final TileProcessor _tileProcessor;
  final TilesetExecutorPreprocessor _preprocessor;
  final TilesetUiPreprocessor _uiPreprocessor;

  CachesTileProvider(this._caches, this._tileProcessor, this._preprocessor,
      this._uiPreprocessor);

  @override
  int get maximumZoom => _caches.vectorTileCache.maximumZoom;

  @override
  Future<TileResponse> provide(TileRequest request) async {
    Map<String, TileData> tileDataBySource = await _retrieve(request);
    Map<String, Tile> tileBySource =
        await _createTiles(request, tileDataBySource);
    var tileset = await _preprocessor.preprocess(request.tileId,
        Tileset(tileBySource), request.zoom.truncate(), request.cancelled);
    tileset = await _uiPreprocessor.preprocess(
        request.tileId, tileset, request.zoom.truncate(), request.cancelled);
    return TileResponse(identity: request.tileId, tileset: tileset);
  }

  Future<Map<String, TileData>> _retrieve(TileRequest request) async {
    Map<String, Future<TileData>> futureBySource = {};
    for (final source in _caches.providerSources) {
      futureBySource[source] = _caches.vectorTileCache
          .retrieve(source, request.tileId, cancelled: request.cancelled);
    }
    Map<String, TileData> tileBySource = {};
    for (final entry in futureBySource.entries) {
      request.testCancelled();
      tileBySource[entry.key] = await entry.value;
    }
    return tileBySource;
  }

  Future<Map<String, Tile>> _createTiles(
      TileRequest request, Map<String, TileData> tileDataBySource) async {
    final sourceToTileFuture = tileDataBySource.map((source, tileData) =>
        MapEntry(source,
            _tileProcessor.process(request, tileData, request.cancelled)));
    Map<String, Tile> tileBySource = {};
    for (final entry in sourceToTileFuture.entries) {
      request.testCancelled();
      tileBySource[entry.key] = await entry.value;
    }
    return tileBySource;
  }
}
