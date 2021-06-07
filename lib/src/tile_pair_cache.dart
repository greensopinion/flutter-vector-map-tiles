import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui';

import 'package:vector_map_tiles/src/abstract_loading_cache.dart';
import 'package:vector_map_tiles/src/tile_cache_key.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../vector_map_tiles.dart';
import 'vector_tile_provider.dart';
import 'vector_tiles.dart';

class TilePairCache extends AbstractLoadingCache<TilePairCacheKey, TilePair> {
  final VectorTileProvider provider;
  final VectorTiles vectorTiles;

  TilePairCache._(Theme theme, VectorTiles vectorTiles,
      VectorTileProvider provider, RenderMode renderMode)
      : this.provider = provider,
        this.vectorTiles = vectorTiles,
        super(TilePairLoader(theme, vectorTiles, renderMode), 20);

  factory TilePairCache(
      Theme theme, VectorTileProvider provider, RenderMode renderMode) {
    final vectorTiles = VectorTiles(provider);
    return TilePairCache._(theme, vectorTiles, provider, renderMode);
  }
}

class TilePairLoader extends Loader<TilePairCacheKey, TilePair> {
  final Theme theme;
  final VectorTiles vectorTiles;
  final ImageRenderer renderer;
  final RenderMode renderMode;

  TilePairLoader(this.theme, this.vectorTiles, this.renderMode)
      : this.renderer = ImageRenderer(theme: theme, scale: _imageScale);

  @override
  Future<TilePair> load(TilePairCacheKey key) async {
    return vectorTiles.retrieveTile(key.tileKey).then((vector) async {
      if (renderMode == RenderMode.mixed) {
        final image = await renderer.render(vector,
            zoomScaleFactor: key.zoomScaleFactor, zoom: key.zoom.toDouble());
        return TilePair(vector, image);
      } else {
        return TilePair(vector, null);
      }
    });
  }
}

class TilePair {
  final VectorTile vector;
  final Image? image;

  TilePair(this.vector, this.image);
}

class TilePairCacheKey {
  final TileCacheKey tileKey;
  final int zoom;
  final double zoomScaleFactor;

  TilePairCacheKey(this.tileKey, this.zoom, this.zoomScaleFactor);

  @override
  operator ==(o) =>
      o is TilePairCacheKey &&
      tileKey == o.tileKey &&
      zoomScaleFactor == o.zoomScaleFactor;

  @override
  int get hashCode => hashValues(tileKey, zoom, zoomScaleFactor);

  @override
  String toString() =>
      'TilePairCacheKey(tileKey=$tileKey,zoom=$zoom,zoomScaleFactor=$zoomScaleFactor)';
}

int _imageScale = 3;
