import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../../vector_map_tiles.dart';
import '../executor/executor.dart';
import '../provider_exception.dart';
import 'memory_cache.dart';
import 'storage_cache.dart';

class VectorTileLoadingCache {
  final Theme _theme;
  final MemoryCache _memoryCache;
  final StorageCache _delegate;
  final TileProviders _providers;
  final Map<String, Future<Tile>> _futuresByKey = {};
  final Executor _executor;
  bool _ready = false;
  final _readyCompleter = Completer<bool>();

  VectorTileLoadingCache(this._delegate, this._memoryCache, this._providers,
      this._executor, this._theme) {
    _initialize();
  }

  int get maximumZoom => _providers.tileProviderBySource.values
      .map((e) => e.maximumZoom)
      .reduce(min);

  Future<Tile> retrieve(String source, TileIdentity tile,
      {required CancellationCallback cancelled}) async {
    if (!_ready) {
      await _readyCompleter.future;
    }
    final key = _toKey(source, tile);
    var future = _futuresByKey[key];
    var loaded = false;
    if (future == null) {
      loaded = true;
      future = _loadTile(source, key, tile, cancelled);
      _futuresByKey[key] = future;
    }
    try {
      return await future;
    } finally {
      if (loaded) {
        _futuresByKey.remove(key);
      }
    }
  }

  void _initialize() async {
    final futures = _executor.submitAll(
        Job('setup theme', _setupTheme, _theme, deduplicationKey: null));
    for (final future in futures) {
      await future;
    }
    _ready = true;
    _readyCompleter.complete(true);
  }

  String _toKey(String source, TileIdentity id) =>
      '${id.z}_${id.x}_${id.y}_$source.pbf';

  Future<Tile> _loadTile(String source, String key, TileIdentity tile,
      CancellationCallback cancelled) async {
    Uint8List bytes;
    try {
      bytes = await _loadBytes(source, key, tile);
    } on ProviderException catch (error) {
      if (error.statusCode == 404) {
        return TileFactory(_theme, Logger.noop())
            .create(VectorTile(layers: []));
      }
      rethrow;
    }
    return _executor.submit(Job('read bytes: $tile', _createTile, bytes,
        cancelled: cancelled, deduplicationKey: 'decode bytes: $tile'));
  }

  Future<Uint8List> _loadBytes(
      String source, String key, TileIdentity tile) async {
    var bytes = _memoryCache.get(key) ?? await _delegate.retrieve(key);
    if (bytes == null) {
      bytes = await _providers.get(source).provide(tile);
      _memoryCache.put(key, bytes);
      await _delegate.put(key, bytes);
    }
    return bytes;
  }
}

Theme? _theme;

Future<void> _setupTheme(Theme theme) async {
  _theme = theme;
}

Tile _createTile(Uint8List bytes) =>
    TileFactory(_theme!, Logger.noop()).create(VectorTileReader().read(bytes));
