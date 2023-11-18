import 'dart:async';
import 'dart:math';

import 'package:executor_lib/executor_lib.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../../vector_map_tiles.dart';

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
      Rectangle<double>? clip, int zoom, CancellationCallback cancelled) async {
    if (!_ready) {
      await _readyCompleter.future;
    }
    final deduplicationKey = 'preprocess: $identity clip=$clip zoom=$zoom';
    final preprocessed = await _executor.submit(Job(deduplicationKey,
        _preprocessTile, _TilesetAndZoom(_preprocessor.theme.id, tileset, zoom),
        cancelled: cancelled, deduplicationKey: deduplicationKey));
    return preprocessed;
  }
}

final _preprocessorByThemeId = <String, TilesetPreprocessor>{};

class _TilesetAndZoom {
  final String themeId;
  final Tileset tileset;
  final int zoom;

  _TilesetAndZoom(this.themeId, this.tileset, this.zoom);
}

Future<void> _setupPreprocessor(TilesetPreprocessor preprocessor) async {
  _preprocessorByThemeId[preprocessor.theme.id] = preprocessor;
}

Tileset _preprocessTile(_TilesetAndZoom it) =>
    _preprocessorByThemeId[it.themeId]!
        .preprocess(it.tileset, zoom: it.zoom.toDouble());
