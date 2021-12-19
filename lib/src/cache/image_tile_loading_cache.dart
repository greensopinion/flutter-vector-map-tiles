import 'dart:ui';

import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../tile_identity.dart';
import 'tile_image_cache.dart';
import '../grid/renderer_pipeline.dart';
import 'cache_stats.dart';

class ImageTileLoadingCache with CacheStats {
  final TileImageCache delegate;
  final RendererPipeline _pipeline;
  final Map<String, _ReferenceCountedImage> _futuresByKey = {};

  ImageTileLoadingCache(this.delegate, this._pipeline);

  double get scale => _pipeline.scale;

  Future<Image> retrieve(
      TileIdentity identity, Map<String, VectorTile> tileBySource,
      {required double zoom}) async {
    final key = _key(identity, zoom: zoom);
    var future = _futuresByKey[key];
    if (future == null) {
      future =
          _ReferenceCountedImage(_load(identity, tileBySource, zoom: zoom));
      _futuresByKey[key] = future;
    } else {
      future.reference();
    }
    final originalImage = await future.image;
    try {
      return originalImage.clone();
    } finally {
      _futuresByKey.remove(key);
      future.dereference();
      if (!future.isReferenced()) {
        originalImage.dispose();
      }
    }
  }

  Future<Image> _load(
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

  String _key(TileIdentity identity, {required double zoom}) {
    return '${identity.z}_${identity.x}_${identity.y}_$zoom';
  }

  String _toModifier(double zoom) {
    return '${scale}_${zoom}_${_pipeline.theme.id}_${_pipeline.theme.version}';
  }
}

class _ReferenceCountedImage {
  final Future<Image> image;
  var _count;

  _ReferenceCountedImage(this.image) {
    _count = 1;
  }

  void reference() {
    ++_count;
  }

  void dereference() {
    --_count;
  }

  bool isReferenced() => _count > 0;
}
