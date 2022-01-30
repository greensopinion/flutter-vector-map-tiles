import 'dart:async';
import 'dart:ui';

import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../../vector_map_tiles.dart';
import '../executor/executor.dart';

enum TileFormat { vector, raster }

abstract class CancellableTileRequest {
  final TileIdentity tileId;
  final CancellationCallback _cancelled;

  CancellableTileRequest(this.tileId, this._cancelled);

  bool get isCancelled => _cancelled();
  CancellationCallback get cancelled => _cancelled;

  void testCancelled() {
    if (isCancelled) {
      throw CancellationException();
    }
  }
}

class TileRequest extends CancellableTileRequest {
  final TileFormat primaryFormat;
  final TileFormat? secondaryFormat;

  TileRequest(
      {required TileIdentity tileId,
      required this.primaryFormat,
      this.secondaryFormat,
      required CancellationCallback cancelled})
      : super(tileId, cancelled);
}

class TileResponse {
  final TileIdentity identity;
  final TileFormat format;
  final Tileset? tileset;
  final Image? image;

  TileResponse(
      {required this.identity, required this.format, this.tileset, this.image});
}

abstract class TileSupplier {
  int get maximumZoom;
  List<Future<TileResponse>> stream(TileRequest request);
}

class TileProviderRequest extends CancellableTileRequest {
  final TileFormat format;
  final double? zoom;

  TileProviderRequest(
      {required TileIdentity tileId,
      required this.format,
      this.zoom,
      required CancellationCallback cancelled})
      : super(tileId, cancelled);
}

abstract class TileProvider {
  int get maximumZoom;
  Future<TileResponse> provide(TileProviderRequest request);
}
