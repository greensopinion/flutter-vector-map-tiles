import 'dart:async';
import 'dart:math';

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
    Rectangle<double>? clip;
    if (tileId.z > maximumZoom) {
      final translation = _translator.specificZoomTranslation(request.tileId,
          zoom: maximumZoom);
      tileId = translation.translated;
      final tileSize = 256;
      final clipSize = tileSize / translation.fraction;
      final buffer = 10;
      final dx = (translation.xOffset * clipSize) - buffer;
      final dy = (translation.yOffset * clipSize) - buffer;
      final sizeWithBuffer = (2 * buffer) + clipSize;
      clip = Rectangle(dx, dy, sizeWithBuffer, sizeWithBuffer);
    }

    return _provider.provide(TileRequest(
        tileId: tileId,
        zoom: request.zoom,
        zoomDetail: request.zoomDetail,
        clip: clip,
        cancelled: request.cancelled));
  }
}
