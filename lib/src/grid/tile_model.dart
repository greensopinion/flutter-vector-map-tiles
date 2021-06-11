import 'package:flutter/widgets.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';
import 'dart:ui' as ui;

import '../cache/caches.dart';
import '../tile_identity.dart';
import 'slippy_map_translator.dart';

typedef ZoomScaleFunction = double Function();
typedef ZoomFunction = double Function();

class VectorTileModel extends ChangeNotifier {
  bool _disposed = false;
  bool get disposed => _disposed;

  final TileIdentity tile;
  final Theme theme;
  final Caches caches;
  final ZoomScaleFunction zoomScaleFunction;
  final ZoomFunction zoomFunction;
  double lastRenderedZoom = double.negativeInfinity;
  double lastRenderedZoomScale = double.negativeInfinity;
  late final TileTranslation translation;
  late TileTranslation imageTranslation;
  VectorTile? vector;
  ui.Image? image;

  VectorTileModel(this.caches, this.theme, this.tile, this.zoomScaleFunction,
      this.zoomFunction) {
    final slippyMap = SlippyMapTranslator(caches.vectorTileCache.maximumZoom);
    translation = slippyMap.translate(tile);
    imageTranslation = translation;
  }

  void startLoading() async {
    final vectorFuture =
        caches.vectorTileCache.retrieve(translation.translated);
    bool loadImage = false;
    await _updateImageIfPresent(translation, zoom: tile.z.toDouble());
    if (!_disposed && this.image == null) {
      final slippyMap = SlippyMapTranslator(caches.vectorTileCache.maximumZoom);
      final alternativeTranslation = slippyMap.lowerZoomAlternative(tile, 1);
      if (alternativeTranslation.translated != translation.translated) {
        loadImage = await _updateImageIfPresent(alternativeTranslation,
            zoom: tile.z.toDouble());
      }
    }
    if (this.image != null) {
      notifyListeners();
    }
    vector = await vectorFuture;
    if (!_disposed && (this.image == null || loadImage)) {
      await _updateImage(translation, vector!, zoom: tile.z.toDouble());
    }
    notifyListeners();
  }

  Future<bool> _updateImage(TileTranslation translation, VectorTile tile,
      {required double zoom}) async {
    final id = translation.translated;
    final image = await caches.imageTileCache.retrieve(id, tile, zoom: zoom);
    caches.memoryImageCache.putImage(id, zoom: zoom, image: image);
    return _applyImage(translation, image);
  }

  Future<bool> _updateImageIfPresent(TileTranslation translation,
      {required double zoom}) async {
    final id = translation.translated;
    var image = caches.memoryImageCache.getImage(id, zoom: zoom);
    if (image == null) {
      image = await caches.imageTileCache.getIfPresent(id, zoom: zoom);
      if (image != null) {
        caches.memoryImageCache.putImage(id, zoom: zoom, image: image);
      }
    }
    return _applyImage(translation, image);
  }

  bool _applyImage(TileTranslation translation, ui.Image? image) {
    if (_disposed) {
      image?.dispose();
      return false;
    }
    this.image = image;
    this.imageTranslation = translation;
    return this.image != null;
  }

  bool updateRendering() {
    final changed = hasChanged();
    if (changed) {
      lastRenderedZoom = zoomFunction();
      lastRenderedZoomScale = zoomScaleFunction();
    }
    return changed;
  }

  bool hasChanged() {
    final lastRenderedZoom = zoomFunction();
    final lastRenderedZoomScale = zoomScaleFunction();
    return lastRenderedZoomScale != this.lastRenderedZoomScale ||
        lastRenderedZoom != this.lastRenderedZoom;
  }

  void requestRepaint() {
    notifyListeners();
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  @override
  void dispose() {
    super.dispose();
    image?.dispose();
    image = null;
    _disposed = true;
  }

  @override
  void removeListener(ui.VoidCallback listener) {
    if (!_disposed) {
      super.removeListener(listener);
    }
  }
}
