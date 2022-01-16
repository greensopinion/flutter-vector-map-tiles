import 'dart:async';

import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../executor/executor.dart';
import 'tile_supplier.dart';

class PreprocessingTileProvider extends TileProvider {
  final TileProvider _delegate;
  final TilesetPreprocessor _preprocessor;
  final Executor _executor;
  bool _ready = false;
  final _readyCompleter = Completer<bool>();

  PreprocessingTileProvider(
      this._delegate, this._preprocessor, this._executor) {
    _initialize();
  }

  void _initialize() async {
    final futures = _executor.submitAll(
        Job('setup preprocessor', _setupPreprocessor, _preprocessor));
    for (final future in futures) {
      await future;
    }
    _ready = true;
    _readyCompleter.complete(true);
  }

  @override
  int get maximumZoom => _delegate.maximumZoom;

  @override
  Future<Tile> provide(TileProviderRequest request) async {
    final tile = await _delegate.provide(request);
    return _preprocess(request, tile);
  }

  Future<Tile> _preprocess(TileProviderRequest request, Tile tile) async {
    if (tile.tileset != null) {
      if (!_ready) {
        await _readyCompleter.future;
      }
      final preprocessed = await _executor.submit(Job(
          'preprocess: ${tile.identity}', _preprocessTile, tile.tileset!,
          cancelled: request.cancelled));
      return Tile(
          identity: tile.identity, format: tile.format, tileset: preprocessed);
    }
    return tile;
  }
}

TilesetPreprocessor? _preprocessor;

Future<void> _setupPreprocessor(TilesetPreprocessor preprocessor) async {
  _preprocessor = preprocessor;
}

Tileset _preprocessTile(Tileset tileset) => _preprocessor!.preprocess(tileset);
