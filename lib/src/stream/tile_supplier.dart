import 'dart:async';
import 'dart:ui';

import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../../vector_map_tiles.dart';

enum TileFormat { vector, raster }

class TileRequest {
  final TileIdentity tileId;
  final TileFormat primaryFormat;
  final TileFormat? secondaryFormat;
  bool _completed = false;

  TileRequest(
      {required this.tileId,
      required this.primaryFormat,
      this.secondaryFormat});

  get completed => _completed;

  /// Indicates that the request is complete, either from the requestor or the
  /// requestee. Can be used to short-circuit a request so that further work
  /// is avoided, i.e. when the results are no longer needed.
  void complete() {
    _completed = true;
  }
}

class Tile {
  final TileIdentity identity;
  final TileFormat format;
  final Tileset? tileset;
  final Image? image;

  Tile(
      {required this.identity, required this.format, this.tileset, this.image});
}

abstract class TileSupplier {
  int get maximumZoom;
  Stream<Tile> stream(TileRequest request);
}

abstract class TileProvider {
  int get maximumZoom;
  Future<Tile> provide(TileIdentity tileIdentity, TileFormat format,
      {double? zoom});
}
