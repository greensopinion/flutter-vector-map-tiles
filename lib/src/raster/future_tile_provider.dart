import 'package:flutter/painting.dart';
import 'package:flutter_map/flutter_map.dart';

class FutureTileProvider extends TileProvider {
  final Future<ImageInfo> Function(
          TileCoordinates coords, TileLayer options, bool Function() cancelled)
      loader;

  FutureTileProvider({required this.loader});

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      _FutureImageProvider(loader, coordinates, options);
}

class _FutureImageProvider extends ImageProvider<_FutureImageProvider> {
  final Future<ImageInfo> Function(
          TileCoordinates coords, TileLayer options, bool Function() cancelled)
      loader;
  final TileCoordinates coords;
  final TileLayer options;

  _FutureImageProvider(this.loader, this.coords, this.options);

  @override
  Future<_FutureImageProvider> obtainKey(ImageConfiguration configuration) {
    return Future.value(this);
  }

  @override
  ImageStreamCompleter loadBuffer(
          _FutureImageProvider key,
          // ignore: deprecated_member_use
          DecoderBufferCallback decode) =>
      _load(key);

  @override
  ImageStreamCompleter loadImage(
          _FutureImageProvider key, ImageDecoderCallback decode) =>
      _load(key);

  ImageStreamCompleter _load(_FutureImageProvider key) {
    final cancellation = _CancellationState();
    final completer = _ImageStreamCompleter();
    completer.addOnLastListenerRemovedCallback(cancellation.cancel);
    _loadImage(cancellation.isCancelled).then((imageInfo) {
      completer.quietlySetImage(imageInfo);
    }, onError: (Object error, StackTrace stack) {
      completer.reportError(exception: error, stack: stack);
    });
    return completer;
  }

  Future<ImageInfo> _loadImage(bool Function() cancelled) =>
      loader(coords, options, cancelled);
}

class _CancellationState {
  bool _cancelled = false;

  void cancel() {
    _cancelled = true;
  }

  bool isCancelled() {
    return _cancelled;
  }
}

class _ImageStreamCompleter extends ImageStreamCompleter {
  void quietlySetImage(ImageInfo image) {
    try {
      super.setImage(image);
    } on StateError catch (_) {
      // expected, disposed
      image.dispose();
    }
  }
}
