import 'dart:async';
import 'dart:ui';

import 'package:vector_map_tiles/src/abstract_loading_cache.dart';
import 'package:vector_map_tiles/src/renderer_pipeline.dart';
import 'package:vector_map_tiles/src/tile_cache_key.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../vector_map_tiles.dart';
import 'vector_tile_provider.dart';

class TilePairCache extends AbstractLoadingCache<TilePairCacheKey, TilePair> {
  final VectorTileProvider provider;

  TilePairCache._(Theme theme, VectorTileProvider provider,
      _TilePairLoader loader, int maxSize)
      : this.provider = provider,
        super(loader, maxSize);

  factory TilePairCache(VectorTileLayerOptions options) {
    final loader = _TilePairLoader(
        options.theme, options.tileProvider, options.renderMode);
    return TilePairCache._(
        options.theme, options.tileProvider, loader, options.maxCachedTiles);
  }
}

class _TilePairLoader extends Loader<TilePairCacheKey, TilePair> {
  final VectorTileProvider tileProvider;
  final RenderMode renderMode;
  final RendererPipeline pipeline;

  _TilePairLoader(Theme theme, this.tileProvider, this.renderMode)
      : this.pipeline = RendererPipeline(theme);

  @override
  Future<TilePair> load(TilePairCacheKey key) async {
    final vectorBytes =
        await tileProvider.provide(key.tileKey.toTileIdentity());
    final vector = VectorTileReader().read(vectorBytes);
    if (renderMode == RenderMode.mixed) {
      final image = await pipeline.renderImage(vector,
          zoomScaleFactor: key.zoomScaleFactor, zoom: key.zoom.toDouble());
      return TilePair(vector, image);
    } else {
      return TilePair(vector, null);
    }
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
