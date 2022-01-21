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
    final futures = _executor.submitAll(Job(
        'setup preprocessor', _setupPreprocessor, _preprocessor,
        deduplicationKey: null));
    for (final future in futures) {
      await future;
    }
    _ready = true;
    _readyCompleter.complete(true);
  }

  @override
  int get maximumZoom => _delegate.maximumZoom;

  @override
  Future<TileResponse> provide(TileProviderRequest request) async {
    final tileresponse = await _delegate.provide(request);
    return _preprocess(request, tileresponse);
  }

  Future<TileResponse> _preprocess(
      TileProviderRequest request, TileResponse tileresponse) async {
    if (tileresponse.tileset != null) {
      if (!_ready) {
        await _readyCompleter.future;
      }
      final deduplicationKey = 'preprocess: ${tileresponse.identity}';
      final preprocessed = await _executor.submit(Job(
          deduplicationKey, _preprocessTile, tileresponse.tileset!,
          cancelled: request.cancelled, deduplicationKey: deduplicationKey));
      return TileResponse(
          identity: tileresponse.identity,
          format: tileresponse.format,
          tileset: preprocessed);
    }
    return tileresponse;
  }
}

TilesetPreprocessor? _preprocessor;

Future<void> _setupPreprocessor(TilesetPreprocessor preprocessor) async {
  _preprocessor = preprocessor;
}

Tileset _preprocessTile(Tileset tileset) => _preprocessor!.preprocess(tileset);
