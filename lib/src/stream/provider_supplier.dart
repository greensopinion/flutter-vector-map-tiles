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
  List<Future<TileResponse>> stream(TileRequest request) {
    TileIdentity tileId = request.tileId;
    if (tileId.z > maximumZoom) {
      tileId = _translator
          .specificZoomTranslation(request.tileId, zoom: maximumZoom)
          .translated;
    }

    // start retrieval right away for the tile that we want
    final futures = [
      _provider.provide(TileProviderRequest(
          tileId: tileId,
          format: request.primaryFormat,
          zoom: request.zoom,
          cancelled: request.cancelled))
    ];
    final secondaryFormat = request.secondaryFormat;
    if (secondaryFormat != null) {
      futures.add(_provider.provide(TileProviderRequest(
          tileId: tileId,
          format: secondaryFormat,
          cancelled: request.cancelled,
          zoom: request.tileId.z.toDouble())));
    }
    return futures;
  }
}
