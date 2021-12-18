import 'package:flutter/widgets.dart';
import '../provider_exception.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';
import 'dart:ui' as ui;

import '../options.dart';
import '../cache/caches.dart';
import '../tile_identity.dart';
import 'slippy_map_translator.dart';

typedef ZoomScaleFunction = double Function();
typedef ZoomFunction = double Function();

class VectorTileModel extends ChangeNotifier {
  bool _disposed = false;
  bool get disposed => _disposed;

  final RenderMode renderMode;
  final TileIdentity tile;
  final Theme theme;
  final Theme? backgroundTheme;
  final Caches caches;
  final bool showTileDebugInfo;
  final ZoomScaleFunction zoomScaleFunction;
  final ZoomFunction zoomFunction;
  double lastRenderedZoom = double.negativeInfinity;
  double lastRenderedZoomScale = double.negativeInfinity;
  late final TileTranslation translation;
  late final TileTranslation? backgroundTranslation;
  late TileTranslation imageTranslation;
  Map<String, VectorTile>? vector;
  Map<String, VectorTile>? backgroundVector;
  ui.Image? image;

  VectorTileModel(
      this.renderMode,
      this.caches,
      this.theme,
      this.backgroundTheme,
      int backgroundZoom,
      this.tile,
      this.zoomScaleFunction,
      this.zoomFunction,
      this.showTileDebugInfo) {
    final slippyMap = SlippyMapTranslator(caches.vectorTileCache.maximumZoom);
    final normalizedTile = tile.normalize();
    translation = slippyMap.translate(normalizedTile);
    if (backgroundZoom >= normalizedTile.z) {
      backgroundZoom = 2;
    }
    backgroundTranslation =
        backgroundTheme != null && normalizedTile.z <= backgroundZoom
            ? null
            : slippyMap.specificZoomTranslation(normalizedTile,
                zoom: backgroundZoom);
    imageTranslation = translation;
  }

  void startLoading() {
    _loadWithAttempts(3);
  }

  void _loadWithAttempts(int attempts) async {
    try {
      await _loadOnce();
    } on ProviderException catch (e, stack) {
      print(e);
      if (e.retryable == Retryable.retry) {
        if (attempts > 0) {
          Future.delayed(Duration(seconds: 3), () {
            if (!_disposed) {
              _loadWithAttempts(attempts - 1);
            }
          });
        } // keep retryable failures quiet
      } else if (e.statusCode != null && e.statusCode == 400) {
        // bad request; unsupported
      } else {
        print(stack);
        rethrow;
      }
    }
  }

  Future<void> _loadOnce() async {
    final vectorFuture = _retrieve(translation.translated);
    final background = backgroundTranslation;
    if (background != null) {
      final backgroundFuture = _retrieve(background.translated);
      backgroundFuture.then((value) {
        if (this.image == null && this.vector == null) {
          backgroundVector = value;
          notifyListeners();
        }
      });
    }
    if (_disposed) {
      return;
    }
    bool loadImage = renderMode == RenderMode.raster;
    if (renderMode != RenderMode.vector && this.image == null) {
      loadImage = _presentImageTilePreviewIfPresent();
      if (this.image != null) {
        notifyListeners();
      }
    }
    Map<String, VectorTile> tileBySource = await vectorFuture;
    if (renderMode != RenderMode.raster) {
      vector = tileBySource;
    }
    if (renderMode != RenderMode.vector &&
        !_disposed &&
        (this.image == null || loadImage)) {
      await _updateImage(translation, tileBySource);
    }
    notifyListeners();
  }

  Future<Map<String, VectorTile>> _retrieve(TileIdentity tile) async {
    Map<String, VectorTile> tileBySource = {};
    for (final source in caches.providerSources) {
      tileBySource[source] =
          await caches.vectorTileCache.retrieve(source, tile);
    }
    return tileBySource;
  }

  Future<bool> _updateImage(
      TileTranslation translation, Map<String, VectorTile> tileBySource) async {
    final id = translation.translated;
    final zoom = translation.original.z.toDouble();
    final image =
        await caches.imageTileCache.retrieve(id, tileBySource, zoom: zoom);
    caches.memoryImageCache.putImage(id, zoom: zoom, image: image);
    return _applyImage(translation, image);
  }

  bool _updateImageIfPresent(TileTranslation translation, {int? minZoom}) {
    final id = translation.translated;
    ui.Image? image;
    if (minZoom == null) {
      minZoom = translation.translated.z;
    }
    for (int z = translation.original.z; z >= minZoom && image == null; --z) {
      image = caches.memoryImageCache.getImage(id, zoom: z.toDouble());
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

  // returns true if alternative was presented
  bool _presentImageTilePreviewIfPresent() {
    _updateImageIfPresent(translation, minZoom: translation.original.z);
    if (!_disposed && this.image == null) {
      var alternativeLoaded = false;
      final slippyMap = SlippyMapTranslator(caches.vectorTileCache.maximumZoom);
      for (var altLevel = 1;
          altLevel < tile.z && altLevel < 3 && !_disposed && !alternativeLoaded;
          ++altLevel) {
        final alternativeTranslation =
            slippyMap.lowerZoomAlternative(tile, levels: altLevel);
        if (alternativeTranslation.translated != translation.translated) {
          alternativeLoaded = _updateImageIfPresent(alternativeTranslation);
        }
      }
      if (!alternativeLoaded) {
        alternativeLoaded = _updateImageIfPresent(translation);
      }
      return alternativeLoaded;
    }
    return false;
  }
}
