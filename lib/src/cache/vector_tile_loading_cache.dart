import 'dart:math';
import 'dart:typed_data';

import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../../vector_map_tiles.dart';
import 'storage_cache.dart';
import 'vector_tile_memory_cache.dart';

class VectorTileLoadingCache {
  final VectorTileMemoryCache _memoryCache;
  final StorageCache _delegate;
  final TileProviders _providers;
  final Map<String, Future<List<int>>> _futuresByKey = {};

  VectorTileLoadingCache(this._delegate, this._memoryCache, this._providers);

  int get maximumZoom => _providers.tileProviderBySource.values
      .map((e) => e.maximumZoom)
      .reduce(min);

  Future<VectorTile?> retrieveIfPresent(String source, TileIdentity tile) =>
      _retrieve(source, tile, onlyIfPresent: true);

  Future<VectorTile> retrieve(String source, TileIdentity tile) async {
    final retrieved = await _retrieve(source, tile, onlyIfPresent: false);
    if (retrieved == null) {
      throw 'illegal state';
    }
    return retrieved;
  }

  Future<VectorTile?> _retrieve(String source, TileIdentity tile,
      {required bool onlyIfPresent}) async {
    var cachedTile = _memoryCache.get(TileKey(tile, source));
    if (cachedTile != null) {
      return cachedTile;
    }
    final key = _toKey(source, tile);
    var future = _futuresByKey[key];
    if (future == null) {
      if (onlyIfPresent) {
        final cached = await _delegate.retrieve(key);
        if (cached == null) {
          return null;
        }
        future = Future.value(cached);
      } else {
        future = _loadBytes(source, key, tile);
      }
      _futuresByKey[key] = future;
    }
    try {
      final bytes = await future;
      final vector = _read(bytes);
      _memoryCache.put(TileKey(tile, source), vector);
      return vector;
    } finally {
      _futuresByKey.remove(key);
    }
  }

  VectorTile _read(List<int> bytes) =>
      VectorTileReader().read(Uint8List.fromList(bytes));

  String _toKey(String source, TileIdentity id) =>
      '${id.z}_${id.x}_${id.y}_$source.pbf';

  Future<List<int>> _loadBytes(
      String source, String key, TileIdentity tile) async {
    var bytes = await _delegate.retrieve(key);
    if (bytes == null) {
      bytes = await _providers.get(source).provide(tile);
      await _delegate.put(key, bytes);
    }
    return bytes;
  }
}
