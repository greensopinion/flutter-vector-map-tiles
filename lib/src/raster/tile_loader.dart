import 'dart:ui';

import 'package:flutter/widgets.dart' hide Image;
import 'package:flutter_map/plugin_api.dart';
import 'storage_image_cache.dart';
import '../grid/grid_tile_positioner.dart';
import '../grid/slippy_map_translator.dart';
import '../stream/tile_supplier.dart';
import '../stream/translating_tile_provider.dart';
import '../../vector_map_tiles.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart' hide TileLayer;

class TileLoader {
  final Theme _theme;
  final TranslatingTileProvider _provider;
  final StorageImageCache _imageCache;

  TileLoader(this._theme, this._provider, this._imageCache);

  Future<ImageInfo> loadTile(Coords<num> coords, TileLayer options) async {
    final requestedTile =
        TileIdentity(coords.z.toInt(), coords.x.toInt(), coords.y.toInt());
    final translator = SlippyMapTranslator(_provider.maximumZoom);
    const scale = 2.0;

    var translation = translator.translate(requestedTile);

    final cached = await _imageCache.retrieve(translation.original);
    if (cached != null) {
      return ImageInfo(image: cached, scale: scale);
    }

    final tileResponse = await _provider.provide(TileRequest(
        tileId: requestedTile,
        zoom: requestedTile.z.toDouble(),
        zoomDetail: requestedTile.z.toDouble(),
        cancelled: () => false));
    final tileset = tileResponse.tileset;
    if (tileset == null) {
      throw 'No tile: $requestedTile';
    }
    if (tileResponse.identity.z != translation.original.z) {
      translation = translator.specificZoomTranslation(requestedTile,
          zoom: tileResponse.identity.z);
    }

    final tileSize = options.tileSize;
    final size = tileSize * scale;
    final tileSizer = GridTileSizer(translation, scale, Size.square(size));

    final rect = Rect.fromLTRB(0, 0, size, size);

    final recorder = PictureRecorder();
    final canvas = Canvas(recorder, rect);
    canvas.clipRect(rect);
    double zoomScaleFactor;
    if (tileSizer.effectiveScale == 1.0) {
      canvas.scale(scale.toDouble(), scale.toDouble());
      zoomScaleFactor = scale;
    } else {
      tileSizer.apply(canvas);
      zoomScaleFactor = tileSizer.effectiveScale / scale;
    }
    final tileClip =
        tileSizer.tileClip(Size.square(size), tileSizer.effectiveScale);

    Renderer(theme: _theme).render(canvas, tileResponse.tileset!,
        zoomScaleFactor: zoomScaleFactor,
        zoom: requestedTile.z.toDouble(),
        clip: tileClip);

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    _cache(translation.original, image);
    return ImageInfo(image: image, scale: scale);
  }

  void _cache(TileIdentity tile, Image image) async {
    Image cloned = image.clone();
    try {
      await _imageCache.put(tile, cloned);
    } catch (_) {
      // nothing to do
    } finally {
      cloned.dispose();
    }
  }
}
