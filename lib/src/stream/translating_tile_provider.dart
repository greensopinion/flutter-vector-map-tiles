import 'dart:async';

import '../tile_identity.dart';
import 'tile_supplier.dart';
import 'translated_tile_request.dart';

class TranslatingTileProvider extends TileProvider {
  final TileProvider _provider;

  TranslatingTileProvider(this._provider);

  @override
  int get maximumZoom => _provider.maximumZoom;

  @override
  Future<TileResponse> provide(TileRequest request) {
    return _provider.provide(_createTranslatedRequest(request));
  }

  @override
  Future<TileResponse> provideLocalCopy(TileRequest request) {
    return _provider.provideLocalCopy(_createTranslatedRequest(request));
  }

  TileRequest _createTranslatedRequest(TileRequest request) {
    TileIdentity tileId = request.tileId;
    if (tileId.z > maximumZoom) {
      return createTranslatedRequest(request, maximumZoom: maximumZoom);
    }
    return request;
  }
}
