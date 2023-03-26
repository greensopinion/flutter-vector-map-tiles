import 'package:flutter/painting.dart';
import 'package:flutter_map/plugin_api.dart';

class FutureTileProvider extends TileProvider {
  final Future<ImageInfo> Function(Coords<num> coords, TileLayer options)
      loader;

  FutureTileProvider({required this.loader});

  @override
  ImageProvider getImage(Coords<num> coords, TileLayer options) =>
      _FutureImageProvider(loader, coords, options);
}

class _FutureImageProvider extends ImageProvider<_FutureImageProvider> {
  final Future<ImageInfo> Function(Coords<num> coords, TileLayer options)
      loader;
  final Coords<num> coords;
  final TileLayer options;

  _FutureImageProvider(this.loader, this.coords, this.options);

  @override
  Future<_FutureImageProvider> obtainKey(ImageConfiguration configuration) {
    return Future.value(this);
  }

  @override
  ImageStreamCompleter loadBuffer(
      _FutureImageProvider key, DecoderBufferCallback decode) {
    return OneFrameImageStreamCompleter(_loadImage());
  }

  Future<ImageInfo> _loadImage() => loader(coords, options);
}
