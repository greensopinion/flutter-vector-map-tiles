import 'dart:math';

import '../grid/slippy_map_translator.dart';
import '../tile_identity.dart';
import 'tile_supplier.dart';

TileRequest createTranslatedRequest(TileRequest request,
    {required int maximumZoom}) {
  TileIdentity tileId = request.tileId;
  if (tileId.z > maximumZoom) {
    final translator = SlippyMapTranslator(maximumZoom);
    final translation =
        translator.specificZoomTranslation(tileId, zoom: maximumZoom);
    tileId = translation.translated;
    if (tileId.isValid()) {
      const tileSize = 256;
      final clipSize = tileSize / translation.fraction;
      const buffer = 10;
      final dx = (translation.xOffset * clipSize) - buffer;
      final dy = (translation.yOffset * clipSize) - buffer;
      final sizeWithBuffer = (2 * buffer) + clipSize;
      final clip = Rectangle(dx, dy, sizeWithBuffer, sizeWithBuffer);
      return TileRequest(
          tileId: tileId,
          zoom: request.zoom,
          zoomDetail: request.zoomDetail,
          clip: clip,
          cancelled: request.cancelled);
    }
  }
  return request;
}
