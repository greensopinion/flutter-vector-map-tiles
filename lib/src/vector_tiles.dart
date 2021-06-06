import 'dart:collection';
import 'dart:ui';

import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

class VectorTiles {
  final _map = LinkedHashMap<_CacheKey, _CacheBucket>();
  final _fetching = Map<_CacheKey, Future<VectorTile>>();
  final _maxSize = 50;
  final VectorTileProvider provider;
  int accessCount = 0;

  VectorTiles(this.provider);

  VectorTile? getTile(TileIdentity tile) {
    final bucket = _map[tile.toCacheKey()];
    if (bucket != null) {
      ++accessCount;
      bucket.accessCount = accessCount;
      return bucket.tile;
    }
    return null;
  }

  Future<VectorTile> retrieveTile(TileIdentity tile) async {
    final cacheKey = tile.toCacheKey();
    _CacheBucket? bucket = _map[cacheKey];
    if (bucket == null) {
      var future = _fetching[cacheKey];
      if (future == null) {
        future = provider.provide(tile).then((bytes) {
          _fetching.remove(cacheKey);
          VectorTile newTile = VectorTileReader().read(bytes);
          ++accessCount;
          _map[cacheKey] = _CacheBucket(newTile, accessCount);
          _constrainCacheSize();
          return newTile;
        }).onError((error, stackTrace) {
          _fetching.remove(cacheKey);
          throw error ?? 'cannot load $tile';
        });
        _fetching[cacheKey] = future;
      }
      return future;
    } else {
      ++accessCount;
      _map.remove(cacheKey);
      bucket.accessCount = accessCount;
      _map[cacheKey] = bucket;
    }
    return Future.value(bucket.tile);
  }

  void _constrainCacheSize() {
    while (_map.length > _maxSize) {
      _map.remove(_map.keys.first);
    }
    if (_map.isNotEmpty) {
      var it = _map.entries.iterator;
      final maxAge = 2 * _maxSize;
      while (it.moveNext()) {
        final entry = it.current;
        final age = accessCount - entry.value.accessCount;
        if (age > maxAge) {
          _map.remove(entry.key);
          it = _map.entries.iterator;
        } else {
          break;
        }
      }
    }
  }
}

class _CacheBucket {
  final VectorTile tile;
  int accessCount;

  _CacheBucket(this.tile, this.accessCount);
}

class _CacheKey {
  final int z;
  final int x;
  final int y;

  _CacheKey(this.z, this.x, this.y);

  @override
  operator ==(o) => o is _CacheKey && x == o.x && y == o.y && z == o.z;

  @override
  int get hashCode => hashValues(x, y, z);

  @override
  String toString() => 'Tile(z=$z,x=$x,y=$y)';
}

extension _TileIdentityExtension on TileIdentity {
  _CacheKey toCacheKey() => _CacheKey(z.toInt(), x.toInt(), y.toInt());
}
