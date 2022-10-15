import 'dart:async';
import 'dart:math';

import 'package:executor_lib/executor_lib.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../../vector_map_tiles.dart';

abstract class CancellableTileRequest {}

class TileRequest extends CancellableTileRequest {
  final TileIdentity tileId;
  final CancellationCallback _cancelled;
  final double zoom;
  final double zoomDetail;
  final Rectangle<double>? clip;

  TileRequest(
      {required this.tileId,
      required this.zoom,
      required this.zoomDetail,
      this.clip,
      required CancellationCallback cancelled})
      : _cancelled = cancelled;

  bool get isCancelled => _cancelled();
  CancellationCallback get cancelled => _cancelled;

  void testCancelled() {
    if (isCancelled) {
      throw CancellationException();
    }
  }
}

class TileResponse {
  final TileIdentity identity;
  final Tileset? tileset;

  TileResponse({required this.identity, this.tileset});
}

abstract class TileProvider {
  int get maximumZoom;
  Future<TileResponse> provide(TileRequest request);
  Future<TileResponse> provideLocalCopy(TileRequest request);
}
