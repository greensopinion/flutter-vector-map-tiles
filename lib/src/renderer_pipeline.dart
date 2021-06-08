import 'dart:async';
import 'dart:ui';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

class RendererPipeline {
  final ImageRenderer _renderer;
  RendererPipeline(Theme theme)
      : _renderer = ImageRenderer(theme: theme, scale: _imageScale);

  Future<Image> renderImage(VectorTile tile,
      {required double zoomScaleFactor, required double zoom}) async {
    return _renderer.render(tile, zoomScaleFactor: zoomScaleFactor, zoom: zoom);
  }
}

int _imageScale = 3;
