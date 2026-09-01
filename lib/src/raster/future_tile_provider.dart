import 'dart:async';

import 'package:executor_lib/executor_lib.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_map/flutter_map.dart';

class FutureTileProvider extends TileProvider {
  final Future<ImageInfo> Function(
          TileCoordinates coords, TileLayer options, bool Function() cancelled)
      loader;

  final String themeIdentity;

  @override
  bool get supportsCancelLoading => true;

  FutureTileProvider({required this.loader, required this.themeIdentity});

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      getImageWithCancelLoadingSupport(
          coordinates, options, Completer().future);

  @override
  ImageProvider getImageWithCancelLoadingSupport(
    TileCoordinates coordinates,
    TileLayer options,
    Future<void> cancelLoading,
  ) =>
      _FutureImageProvider(
          loader, themeIdentity, coordinates, options, cancelLoading);
}

/// The key under which a rendered tile is stored in Flutter's [ImageCache].
///
/// Including [themeIdentity] makes cached images self-invalidating: a theme
/// change or version bump yields different keys rather than reusing stale
/// renderings, so no explicit eviction is required.
@immutable
class _TileImageKey {
  final String themeIdentity;
  final TileCoordinates coords;
  final int tileDimension;

  const _TileImageKey(this.themeIdentity, this.coords, this.tileDimension);

  @override
  bool operator ==(Object other) =>
      other is _TileImageKey &&
      other.themeIdentity == themeIdentity &&
      other.coords == coords &&
      other.tileDimension == tileDimension;

  @override
  int get hashCode => Object.hash(themeIdentity, coords, tileDimension);

  @override
  String toString() =>
      '_TileImageKey($themeIdentity, $coords, tileDimension: $tileDimension)';
}

/// Provides a tile image by rendering it with [loader].
class _FutureImageProvider extends ImageProvider<_TileImageKey> {
  final Future<ImageInfo> Function(
          TileCoordinates coords, TileLayer options, bool Function() cancelled)
      loader;
  final String themeIdentity;
  final TileCoordinates coords;
  final TileLayer options;
  final Future<void> cancelLoading;

  _FutureImageProvider(this.loader, this.themeIdentity, this.coords,
      this.options, this.cancelLoading);

  @override
  Future<_TileImageKey> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(
          _TileImageKey(themeIdentity, coords, options.tileDimension));

  @override
  ImageStreamCompleter loadBuffer(
          _TileImageKey key,
          // ignore: deprecated_member_use
          DecoderBufferCallback decode) =>
      _load();

  @override
  ImageStreamCompleter loadImage(
          _TileImageKey key, ImageDecoderCallback decode) =>
      _load();

  ImageStreamCompleter _load() {
    final cancellation = _CancellationState();
    final completer = _ImageStreamCompleter();
    unawaited(cancelLoading.whenComplete(cancellation.cancel));
    completer.addOnLastListenerRemovedCallback(cancellation.cancel);
    _loadImage(cancellation.isCancelled).then((imageInfo) {
      completer.quietlySetImage(imageInfo);
    }, onError: (Object error, StackTrace stack) {
      if (error is! CancellationException) {
        completer.reportError(exception: error, stack: stack);
      }
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
