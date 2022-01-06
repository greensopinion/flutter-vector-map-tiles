import 'dart:async';
import 'dart:math';

import '../tile_identity.dart';

import '../grid/slippy_map_translator.dart';
import 'tile_supplier.dart';

class ProviderTileSupplier extends TileSupplier {
  final TileProvider _provider;
  final SlippyMapTranslator _translator;
  final _maxAlternativeLevels = 2;

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
      final readyTile =
          await _provideTileOrAlternativeIfReady(request, secondaryFormat);
      if (readyTile != null) {
        yield readyTile;
      }
      if (!request.completed &&
          (readyTile == null || readyTile.identity.z != tileId.z)) {
        final imageTile = _provider
            .provide(tileId, secondaryFormat, zoom: request.tileId.z.toDouble())
            .toCompleter();
        if (mainTile.isCompleted) {
          yield await mainTile.future;
          providedMainTile = true;
        }
        yield await imageTile.future;
        if (mainTile.isCompleted) {
          yield await mainTile.future;
          providedMainTile = true;
        }
      }
    }
    if (!request.completed && !providedMainTile) {
      final tileOrAlternative = await _provideTileOrAlternativeIfReady(
          request, request.primaryFormat);
      if (tileOrAlternative != null) {
        yield tileOrAlternative;
        providedMainTile = tileOrAlternative.identity.z == tileId.z;
      }
      if (!request.completed && !providedMainTile) {
        yield await mainTile.future;
      }
    }
    request.complete();
  }

  Future<Tile?> _provideTileOrAlternativeIfReady(
      TileRequest request, TileFormat format) async {
    var startZoom = min(request.tileId.z, maximumZoom);
    for (var translationLevel = 0;
        translationLevel < _maxAlternativeLevels;
        ++translationLevel) {
      final newZoom = startZoom - translationLevel;
      if (newZoom < 1) {
        break;
      }
      final newTranslation =
          _translator.specificZoomTranslation(request.tileId, zoom: newZoom);
      var tile = await _provider.provideIfReady(
          newTranslation.translated, format,
          zoom: request.tileId.z.toDouble());
      if (tile == null && format == TileFormat.raster && request.tileId.z > 3) {
        tile = await _provider.provideIfReady(newTranslation.translated, format,
            zoom: (request.tileId.z - 1).toDouble());
      }
      if (tile != null) {
        return tile;
      }
    }
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
