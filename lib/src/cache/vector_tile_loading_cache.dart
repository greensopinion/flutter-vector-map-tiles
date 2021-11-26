import 'dart:typed_data';

import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../tile_identity.dart';
import '../vector_tile_provider.dart';
import 'storage_cache.dart';

class VectorTileLoadingCache {
  final StorageCache _delegate;
  final VectorTileProvider _provider;
  final String _cacheId;

  VectorTileLoadingCache(this._delegate, this._provider, this._cacheId);

  int get maximumZoom => _provider.maximumZoom;

  Future<VectorTile> retrieve(TileIdentity tile) async {
    final key = _toKey(tile);
    var bytes = await _delegate.retrieve(key);
    if (bytes == null) {
      bytes = await _provider.provide(tile);
      await _delegate.put(key, bytes);
    }
    return VectorTileReader().read(Uint8List.fromList(bytes));
  }

  Future<VectorTile?> getIfPresent(TileIdentity tile) async {
    final bytes = await _delegate.retrieve(_toKey(tile));
    if (bytes != null) {
      return VectorTileReader().read(Uint8List.fromList(bytes));
    }
  }

  String _toKey(TileIdentity id) => '${_cacheId}_${id.z}_${id.x}_${id.y}.pbf';
}
