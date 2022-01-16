import 'dart:ui';

import '../executor/executor.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../grid/renderer_pipeline.dart';
import '../tile_identity.dart';
import 'cache_stats.dart';
import 'tile_image_cache.dart';

class ImageTileLoadingCache with CacheStats {
  final TileImageCache delegate;
  final RendererPipeline _pipeline;
  final Map<String, _ReferenceCountedImage> _futuresByKey = {};

  ImageTileLoadingCache(this.delegate, this._pipeline);

  double get scale => _pipeline.scale;

  Future<Image> retrieve(TileIdentity identity, Tileset tileset,
      {required int zoom, required CancellationCallback cancelled}) async {
    final key = _key(identity, zoom: zoom);
    var future = _futuresByKey[key];
    if (future == null) {
      future = _ReferenceCountedImage(
          _load(identity, tileset, zoom: zoom, cancelled: cancelled));
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

  Future<Image> _load(TileIdentity identity, Tileset tileset,
      {required int zoom, required CancellationCallback cancelled}) async {
    final modifier = _toModifier(zoom);
    final image = await delegate.retrieve(identity, modifier);
    if (image == null) {
      cacheMiss();
      final rendered = await _pipeline.renderImage(identity, tileset, zoom,
          cancelled: cancelled);
      await delegate.put(identity, rendered, modifier);
      return rendered;
    } else {
      cacheHit();
    }
    return image;
  }

  String _key(TileIdentity identity, {required int zoom}) {
    return '${identity.z}_${identity.x}_${identity.y}_$zoom';
  }

  String _toModifier(int zoom) {
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
