import 'dart:async';
import 'dart:math';

import 'package:executor_lib/executor_lib.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import 'tile_supplier.dart';

class TileProcessor {
  final Executor _executor;

  TileProcessor(this._executor);

  Future<Tile> process(TileRequest request, String source, TileData tileData,
      CancellationCallback cancelled) {
    final key = 'process $source ${request.tileId.key()} clip=${request.clip}';
    return _executor.submit(Job<_Request, Tile>(
        key, _processTile, _Request(tileData, request.clip),
        cancelled: cancelled, deduplicationKey: key));
  }
}

class _Request {
  final TileData tileData;
  final Rectangle<double>? clip;

  _Request(this.tileData, this.clip);
}

FutureOr<Tile> _processTile(_Request request) {
  var tileData = request.tileData;
  if (request.clip != null) {
    final clipper = TileClip(bounds: request.clip!);
    tileData = clipper.clip(tileData);
  }
  return tileData.toTile();
}
