import 'dart:async';
import 'dart:math';

import 'package:executor_lib/executor_lib.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../../vector_map_tiles.dart';

class TilesetUiPreprocessor {
  final TilesetPreprocessor _preprocessor;
  final Executor _executor;

  TilesetUiPreprocessor(this._preprocessor) : _executor = QueueExecutor();

  Future<Tileset> preprocess(TileIdentity identity, Tileset tileset,
      Rectangle<double>? clip, int zoom, CancellationCallback cancelled) async {
    final deduplicationKey = 'preprocess ui: $identity clip=$clip zoom=$zoom';
    return await _executor.submit(Job(
        deduplicationKey, _preprocessTile, _TilesetAndZoom(tileset, zoom),
        cancelled: cancelled, deduplicationKey: deduplicationKey));
  }

  Tileset _preprocessTile(_TilesetAndZoom job) {
    return _preprocessor.preprocess(job.tileset, zoom: job.zoom.toDouble());
  }
}

class _TilesetAndZoom {
  final Tileset tileset;
  final int zoom;

  _TilesetAndZoom(this.tileset, this.zoom);
}
