import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:executor_lib/executor_lib.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import 'extensions.dart';
import 'storage_cache.dart';

class AtlasImageCache {
  final Theme _theme;
  final Future<Uint8List> Function() _atlasProvider;
  final StorageCache _delegate;
  bool _disposed = false;
  Image? _image;
  Completer<Image>? _loading;

  AtlasImageCache(this._theme, this._atlasProvider, this._delegate);

  Future<Image> retrieve() {
    if (_disposed) {
      return Future.error(CancellationException());
    }
    final image = _image;
    if (image != null) {
      return Future.value(image);
    }
    var loading = _loading;
    if (loading != null) {
      return loading.future;
    }
    final loadResult = Completer<Image>();
    _loading = loadResult;
    _load().then((value) {
      if (_disposed) {
        value.dispose();
        loadResult.completeError(CancellationException());
      } else {
        loadResult.complete(value);
      }
    }).onError((error, stackTrace) {
      loadResult.completeError(error ?? '', stackTrace);
    });
    return loadResult.future;
  }

  void dispose() {
    _disposed = true;
    _image?.dispose();
    _image = null;
  }

  Future<Image> _load() async {
    final key = _key();
    var bytes = await _delegate.retrieve(key);
    if (bytes == null) {
      bytes = await _atlasProvider();
      await _delegate.put(key, bytes);
    }
    final codec = await instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  String _key() =>
      'icon-atlas-${_theme.id.fileSafe()}-${_theme.version.fileSafe()}.png';
}
