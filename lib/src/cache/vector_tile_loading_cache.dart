import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:executor_lib/executor_lib.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../provider_exception.dart';
import '../tile_identity.dart';
import '../tile_providers.dart';
import '../vector_tile_provider.dart';
import 'memory_cache.dart';
import 'storage_cache.dart';

class VectorTileLoadingCache {
  final Theme _theme;
  final MemoryTileDataCache _tileDataCache;
  final MemoryCache _memoryCache;
  final StorageCache _delegate;
  final TileProviders _providers;
  final Map<String, Future<Uint8List?>> _byteFuturesByKey = {};
  final Map<String, Future<Uint8List?>> _cacheByteFuturesByKey = {};
  final Executor _executor;
  bool _ready = false;
  final _readyCompleter = Completer<bool>();
  late final int maximumZoom;

  VectorTileLoadingCache(this._delegate, this._memoryCache, this._tileDataCache,
      this._providers, this._executor, this._theme) {
    maximumZoom = _providers.tileProviderBySource.values
        .map((e) => e.maximumZoom)
        .reduce(min);
    _initialize();
  }

  Future<TileData?> retrieve(String source, TileIdentity tile,
      {required CancellationCallback cancelled,
      required bool cachedOnly}) async {
    if (!_ready) {
      await _readyCompleter.future;
    }
    final key = _toKey(source, tile);
    return await _loadTile(source, key, tile, cancelled, cachedOnly);
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

  Future<TileData?> _loadTile(String source, String key, TileIdentity tile,
      CancellationCallback cancelled, bool cachedOnly) async {
    final cached = _tileDataCache.get(key);
    if (cached != null) {
      return cached;
    }
    var future =
        cachedOnly ? _cacheByteFuturesByKey[key] : _byteFuturesByKey[key];
    var loaded = false;
    if (future == null) {
      final provider = _providers.get(source);
      if (tile.z < provider.minimumZoom) {
        return _emptyTile();
      }
      loaded = true;
      future = _loadBytes(provider, key, tile, cachedOnly);
      if (cachedOnly) {
        _cacheByteFuturesByKey[key] = future;
      } else {
        _byteFuturesByKey[key] = future;
      }
    }
    Uint8List? bytes;
    try {
      bytes = await future;
    } on ProviderException catch (error) {
      if (error.statusCode == 404 || error.statusCode == 204) {
        return _emptyTile();
      }
      rethrow;
    } finally {
      if (loaded) {
        if (cachedOnly) {
          _cacheByteFuturesByKey.remove(key);
        } else {
          _byteFuturesByKey.remove(key);
        }
      }
    }
    if (bytes == null) {
      return null;
    }
    final name = '$key/${_theme.id}';
    final tileData = await _executor.submit(Job(
        name, _createTile, _ThemeTile(themeId: _theme.id, bytes: bytes),
        cancelled: cancelled, deduplicationKey: name));
    _tileDataCache.put(key, tileData);
    return tileData;
  }

  Future<Uint8List?> _loadBytes(VectorTileProvider provider, String key,
      TileIdentity tile, bool cachedOnly) async {
    var bytes = _memoryCache.get(key) ?? await _delegate.retrieve(key);
    if (bytes == null && !cachedOnly) {
      bytes = await provider.provide(tile);
      _memoryCache.put(key, bytes);
      await _delegate.put(key, bytes);
    }
    return bytes;
  }

  TileData _emptyTile() => TileFactory(_theme, const Logger.noop())
      .createTileData(VectorTile(layers: []));
}

class _ThemeTile {
  final String themeId;
  final Uint8List bytes;

  _ThemeTile({required this.themeId, required this.bytes});
}

final _themeById = <String, Theme>{};

Future<void> _setupTheme(Theme theme) async {
  _themeById[theme.id] = theme;
}

TileData _createTile(_ThemeTile themeTile) =>
    TileFactory(_themeById[themeTile.themeId]!, const Logger.noop())
        .createTileData(VectorTileReader().read(themeTile.bytes));
