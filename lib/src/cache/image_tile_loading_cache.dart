import 'dart:ui';

import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../tile_identity.dart';
import 'tile_image_cache.dart';
import '../grid/renderer_pipeline.dart';
import 'cache_stats.dart';

class ImageTileLoadingCache with CacheStats {
  final TileImageCache delegate;
  final RendererPipeline _pipeline;

  ImageTileLoadingCache(this.delegate, this._pipeline);

  double get scale => _pipeline.scale;

  Future<Image> retrieve(
      TileIdentity identity, Map<String, VectorTile> tileBySource,
      {required double zoom}) async {
    final modifier = _toModifier(zoom);

    final image = await delegate.retrieve(identity, modifier);
    if (image == null) {
      cacheMiss();
      final rendered =
          await _pipeline.renderImage(identity, tileBySource, zoom);
      await delegate.put(identity, rendered, modifier);
      return rendered;
    } else {
      cacheHit();
    }
    return image;
  }

  String _toModifier(double zoom) {
    return '${scale}_${zoom}_${_pipeline.theme.id}_${_pipeline.theme.version}';
  }
}
