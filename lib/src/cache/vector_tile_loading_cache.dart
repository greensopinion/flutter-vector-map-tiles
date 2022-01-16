import 'dart:math';
import 'dart:typed_data';

import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../../vector_map_tiles.dart';
import '../executor/executor.dart';
import 'memory_cache.dart';
import 'storage_cache.dart';

class VectorTileLoadingCache {
  final MemoryCache _memoryCache;
  final StorageCache _delegate;
  final TileProviders _providers;
  final Map<String, Future<VectorTile>> _futuresByKey = {};
  final Executor _executor;

  VectorTileLoadingCache(
      this._delegate, this._memoryCache, this._providers, this._executor);

  int get maximumZoom => _providers.tileProviderBySource.values
      .map((e) => e.maximumZoom)
      .reduce(min);

  Future<VectorTile> retrieve(String source, TileIdentity tile,
      {required CancellationCallback cancelled}) async {
    final key = _toKey(source, tile);
    var future = _futuresByKey[key];
    var loaded = false;
    if (future == null) {
      loaded = true;
      future = _loadTile(source, key, tile, cancelled);
      _futuresByKey[key] = future;
    }
    try {
      return await future;
    } finally {
      if (loaded) {
        _futuresByKey.remove(key);
      }
    }
  }

  String _toKey(String source, TileIdentity id) =>
      '${id.z}_${id.x}_${id.y}_$source.pbf';

  Future<VectorTile> _loadTile(String source, String key, TileIdentity tile,
      CancellationCallback cancelled) async {
    final bytes = await _loadBytes(source, key, tile);
    return _executor.submit(Job('read bytes: $tile', _readTileBytes, bytes,
        cancelled: cancelled, deduplicationKey: 'decode bytes: $tile'));
  }

  Future<Uint8List> _loadBytes(
      String source, String key, TileIdentity tile) async {
    var bytes = _memoryCache.get(key) ?? await _delegate.retrieve(key);
    if (bytes == null) {
      bytes = await _providers.get(source).provide(tile);
      _memoryCache.put(key, bytes);
      await _delegate.put(key, bytes);
    }
    return bytes;
  }
}

VectorTile _readTileBytes(Uint8List bytes) => VectorTileReader().read(bytes);
