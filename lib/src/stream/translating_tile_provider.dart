import 'dart:async';

import '../grid/slippy_map_translator.dart';
import '../tile_identity.dart';
import 'tile_supplier.dart';

class TranslatingTileProvider extends TileProvider {
  final TileProvider _provider;
  final SlippyMapTranslator _translator;

  TranslatingTileProvider(this._provider)
      : _translator = SlippyMapTranslator(_provider.maximumZoom);

  @override
  int get maximumZoom => _provider.maximumZoom;

  @override
  Future<TileResponse> provide(TileRequest request) {
    TileIdentity tileId = request.tileId;
    if (tileId.z > maximumZoom) {
      tileId = _translator
          .specificZoomTranslation(request.tileId, zoom: maximumZoom)
          .translated;
    }

    return _provider.provide(TileRequest(
        tileId: tileId,
        zoom: request.zoom,
        zoomDetail: request.zoomDetail,
        cancelled: request.cancelled));
  }
}
