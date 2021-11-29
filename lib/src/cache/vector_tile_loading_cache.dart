import 'dart:math';
import 'dart:typed_data';

import '../../vector_map_tiles.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../tile_identity.dart';
import 'storage_cache.dart';

class VectorTileLoadingCache {
  final StorageCache _delegate;
  final TileProviders _providers;

  VectorTileLoadingCache(this._delegate, this._providers);

  int get maximumZoom => _providers.tileProviderBySource.values
      .map((e) => e.maximumZoom)
      .reduce(min);

  Future<VectorTile> retrieve(String source, TileIdentity tile) async {
    final key = _toKey(source, tile);
    var bytes = await _delegate.retrieve(key);
    if (bytes == null) {
      bytes = await _providers.get(source).provide(tile);
      await _delegate.put(key, bytes);
    }
    return VectorTileReader().read(Uint8List.fromList(bytes));
  }

  String _toKey(String source, TileIdentity id) =>
      '${id.z}_${id.x}_${id.y}_$source.pbf';
}
