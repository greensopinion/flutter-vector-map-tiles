import 'dart:ui';

import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../tile_identity.dart';
import 'tile_image_cache.dart';
import '../renderer_pipeline.dart';

class ImageTileLoadingCache {
  final TileImageCache _delegate;
  final RendererPipeline _pipeline;

  ImageTileLoadingCache(this._delegate, this._pipeline);

  double get scale => _pipeline.scale;

  Future<Image> retrieve(TileIdentity identity, VectorTile tile,
      {required double zoom}) async {
    final modifier = _toModifier(zoom);

    final image = await _delegate.retrieve(identity, modifier);
    if (image == null) {
      final rendered = await _pipeline.renderImage(identity, tile, zoom);
      await _delegate.put(identity, rendered, modifier);
      return rendered;
    }
    return image;
  }

  Future<Image?> getIfPresent(TileIdentity identity, VectorTile tile,
      {required double zoom}) {
    return _delegate.retrieve(identity, _toModifier(zoom));
  }

  String _toModifier(double zoom) {
    return '${scale}_$zoom';
  }
}
