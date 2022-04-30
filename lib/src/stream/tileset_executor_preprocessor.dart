import 'dart:async';

import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../../vector_map_tiles.dart';
import '../executor/executor.dart';

class TilesetExecutorPreprocessor {
  final TilesetPreprocessor _preprocessor;
  final Executor _executor;
  bool _ready = false;
  final _readyCompleter = Completer<bool>();

  TilesetExecutorPreprocessor(this._preprocessor, this._executor) {
    _initialize();
  }

  void _initialize() async {
    final futures = _executor.submitAll(Job(
        'setup preprocessor', _setupPreprocessor, _preprocessor,
        deduplicationKey: null));
    for (final future in futures) {
      await future;
    }
    _ready = true;
    _readyCompleter.complete(true);
  }

  Future<Tileset> preprocess(TileIdentity identity, Tileset tileset, int zoom,
      CancellationCallback cancelled) async {
    if (!_ready) {
      await _readyCompleter.future;
    }
    final deduplicationKey = 'preprocess: $identity';
    final preprocessed = await _executor.submit(Job(
        deduplicationKey, _preprocessTile, _TilesetAndZoom(tileset, zoom),
        cancelled: cancelled, deduplicationKey: deduplicationKey));
    return preprocessed;
  }
}

TilesetPreprocessor? _preprocessor;

class _TilesetAndZoom {
  final Tileset tileset;
  final int zoom;

  _TilesetAndZoom(this.tileset, this.zoom);
}

Future<void> _setupPreprocessor(TilesetPreprocessor preprocessor) async {
  _preprocessor = preprocessor;
}

Tileset _preprocessTile(_TilesetAndZoom it) =>
    _preprocessor!.preprocess(it.tileset, zoom: it.zoom.toDouble());
