import 'dart:typed_data';

import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../layout/tile_position.dart';
import '../tile_identity.dart';

class TileDataModel {
  late final TileIdentity tile;
  TilePosition tilePosition;
  bool isLoaded = false;
  bool isDisplayReady = false;
  bool preRenderStarted = false;
  Tileset? tileset;
  RasterTileset? rasterTileset;
  List<Map<String, Uint8List>>? renderData;

  TileDataModel(this.tilePosition) : tile = tilePosition.tile;

  void dispose() {
    isLoaded = false;
    isDisplayReady = false;
    preRenderStarted = false;
    rasterTileset?.dispose();
    rasterTileset = null;
    tileset = null;
    renderData = null;
  }
}
