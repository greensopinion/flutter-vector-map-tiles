import 'dart:async';

import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

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

  Future<Tileset> preprocess(TileIdentity identity, Tileset tileset,
      CancellationCallback cancelled) async {
    if (!_ready) {
      await _readyCompleter.future;
    }
    final deduplicationKey = 'preprocess: $identity';
    final preprocessed = await _executor.submit(Job(
        deduplicationKey, _preprocessTile, tileset,
        cancelled: cancelled, deduplicationKey: deduplicationKey));
    return preprocessed;
  }
}

TilesetPreprocessor? _preprocessor;

Future<void> _setupPreprocessor(TilesetPreprocessor preprocessor) async {
  _preprocessor = preprocessor;
}

Tileset _preprocessTile(Tileset tileset) => _preprocessor!.preprocess(tileset);
