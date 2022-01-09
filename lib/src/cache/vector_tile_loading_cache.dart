import 'dart:math';
import 'dart:typed_data';

import 'package:vector_map_tiles/src/executor/executor.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../../vector_map_tiles.dart';
import 'storage_cache.dart';
import 'vector_tile_memory_cache.dart';

class VectorTileLoadingCache {
  final VectorTileMemoryCache _memoryCache;
  final StorageCache _delegate;
  final TileProviders _providers;
  final Map<String, Future<VectorTile>> _futuresByKey = {};
  final Executor _executor;

  VectorTileLoadingCache(
      this._delegate, this._memoryCache, this._providers, this._executor);

  int get maximumZoom => _providers.tileProviderBySource.values
      .map((e) => e.maximumZoom)
      .reduce(min);

  Future<VectorTile> retrieve(String source, TileIdentity tile) async {
    var cachedTile = _memoryCache.get(TileKey(tile, source));
    if (cachedTile != null) {
      return cachedTile;
    }
    final key = _toKey(source, tile);
    var future = _futuresByKey[key];
    if (future == null) {
      future = _loadTile(source, key, tile);
      _futuresByKey[key] = future;
    }
    try {
      final vector = await future;
      _memoryCache.put(TileKey(tile, source), vector);
      return vector;
    } finally {
      _futuresByKey.remove(key);
    }
  }

  String _toKey(String source, TileIdentity id) =>
      '${id.z}_${id.x}_${id.y}_$source.pbf';

  Future<VectorTile> _loadTile(
      String source, String key, TileIdentity tile) async {
    final bytes = await _loadBytes(source, key, tile);
    return _executor.submit(_readTileBytes, bytes);
  }

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

VectorTile _readTileBytes(List<int> bytes) =>
    VectorTileReader().read(Uint8List.fromList(bytes));
