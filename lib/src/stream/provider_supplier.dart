import 'dart:async';

import '../tile_identity.dart';

import '../grid/slippy_map_translator.dart';
import 'tile_supplier.dart';

class ProviderTileSupplier extends TileSupplier {
  final TileProvider _provider;
  final SlippyMapTranslator _translator;

  ProviderTileSupplier(this._provider)
      : _translator = SlippyMapTranslator(_provider.maximumZoom);

  @override
  int get maximumZoom => _provider.maximumZoom;

  @override
  Stream<Tile> stream(TileRequest request) async* {
    TileIdentity tileId = request.tileId;
    if (tileId.z > maximumZoom) {
      tileId = _translator
          .specificZoomTranslation(request.tileId, zoom: maximumZoom)
          .translated;
    }

    // start retrieval right away for the tile that we want
    final mainTile =
        _provider.provide(tileId, request.primaryFormat).toCompleter();
    var providedMainTile = false;

    final secondaryFormat = request.secondaryFormat;
    if (secondaryFormat != null) {
      final secondary = _provider
          .provide(tileId, secondaryFormat, zoom: request.tileId.z.toDouble())
          .toCompleter();
      if (mainTile.isCompleted) {
        yield await mainTile.future;
        providedMainTile = true;
      }
      final secondaryTile = await secondary.future;
      if (mainTile.isCompleted) {
        yield await mainTile.future;
        providedMainTile = true;
      }
      yield secondaryTile;
    }
    if (!request.completed && !providedMainTile) {
      yield await mainTile.future;
    }
    request.complete();
  }
}

extension _FutureExtension<T> on Future<T> {
  Completer<T> toCompleter() {
    final completer = Completer<T>();
    then((value) => completer.complete(value)).onError((error, stackTrace) =>
        completer.completeError(error ?? 'error', stackTrace));
    return completer;
  }
}
