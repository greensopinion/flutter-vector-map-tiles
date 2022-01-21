import 'dart:async';

import '../grid/slippy_map_translator.dart';
import '../tile_identity.dart';
import 'tile_supplier.dart';

class ProviderTileSupplier extends TileSupplier {
  final TileProvider _provider;
  final SlippyMapTranslator _translator;

  ProviderTileSupplier(this._provider)
      : _translator = SlippyMapTranslator(_provider.maximumZoom);

  @override
  int get maximumZoom => _provider.maximumZoom;

  @override
  Stream<TileResponse> stream(TileRequest request) {
    TileIdentity tileId = request.tileId;
    if (tileId.z > maximumZoom) {
      tileId = _translator
          .specificZoomTranslation(request.tileId, zoom: maximumZoom)
          .translated;
    }

    final streamController = _StreamFutureState();
    // start retrieval right away for the tile that we want
    streamController.add(_provider.provide(TileProviderRequest(
        tileId: tileId,
        format: request.primaryFormat,
        cancelled: request.cancelled)));
    final secondaryFormat = request.secondaryFormat;
    if (secondaryFormat != null) {
      streamController.add(_provider.provide(TileProviderRequest(
          tileId: tileId,
          format: secondaryFormat,
          cancelled: request.cancelled,
          zoom: request.tileId.z.toDouble())));
    }
    return streamController.stream;
  }
}

class _StreamFutureState {
  var _count = 0;
  final _controller = StreamController<TileResponse>();

  Stream<TileResponse> get stream => _controller.stream;

  void add(Future<TileResponse> future) {
    ++_count;
    future.then((value) {
      _controller.sink.add(value);
      _countDown();
    }).onError((error, stackTrace) {
      _controller.sink.addError(error ?? 'unknown', stackTrace);
      _countDown();
    });
  }

  void _countDown() {
    if (--_count == 0) {
      _controller.close();
    }
  }
}
