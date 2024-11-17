import 'dart:async';
import 'dart:io';

import 'package:executor_lib/executor_lib.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../vector_map_tiles.dart';
import '../cache/byte_storage_factory_io.dart';
import '../cache/byte_storage_io.dart';
import '../cache/caches.dart';
import '../cache/storage_cache.dart';
import '../extensions.dart';
import '../stream/tile_supplier_raster.dart';
import 'future_tile_provider.dart';
import 'raster_tile_provider.dart';
import 'storage_image_cache.dart';
import 'tile_loader.dart';
import 'ui_isolate_executor.dart';

typedef EntrypointFunction = void Function(dynamic message);
typedef StyleFunction = Future<Style> Function();
typedef IsolateCallback = Future Function(
    {required StyleFunction style, required dynamic initialMessage});

IsolateCallback renderTileEntrypoint =
    ({required initialMessage, required StyleFunction style}) async {
  await executeIsolateMessages(
      initialMessage: initialMessage,
      executor: _IsolateTileRenderer(styleFunction: style).accept);
};

class IsolateTileLoader {
  final EntrypointFunction entrypoint;
  final Map? entrypointParamters;
  final Duration ttl = _defaultTtl;
  final int maxSizeInBytes = 1024 * 1024 * 200;
  late final StorageCache cache;
  late final Executor _executor;
  Future<StorageImageCache>? _imageCache;

  IsolateTileLoader(
      {required this.entrypoint,
      required this.entrypointParamters,
      concurrency = 4}) {
    cache = StorageCache(
        IoByteStorage(pather: cacheStorageResolver), ttl, maxSizeInBytes);
    _executor = PoolExecutor(
        concurrency: 4,
        executorFactory: () => ConcurrencyExecutor(
            concurrencyLimit: 2,
            maxQueueSize: 1000,
            delegate: UiIsolateExecutor(
                entrypoint: entrypoint,
                entrypointParameters: entrypointParamters)));
  }

  TileProvider provider() {
    return FutureTileProvider(loader: _loadTile, disposer: _dispose);
  }

  Future<ImageInfo> _loadTile(TileCoordinates coords, TileLayer options,
      bool Function() cancelled) async {
    final TileIdentity tile = coords.toTileIdentity();
    StorageImageCache imageCache = await _loadImageCache();
    var image = await imageCache.retrieve(tile);
    if (image == null) {
      await _fillCache(coords, options.tileSize, cancelled);
      image = await imageCache.retrieve(tile);
    }
    if (image == null) {
      throw Exception(
          'Cannot provide tile: ${coords.z},${coords.x},${coords.y}');
    }
    return ImageInfo(image: image);
  }

  void _dispose() {
    _executor.dispose();
  }

  Future<StorageImageCache> _loadImageCache() async {
    Future<StorageImageCache>? imageCache = _imageCache;
    if (imageCache == null) {
      final completer = Completer<StorageImageCache>();
      imageCache = completer.future;
      _imageCache = imageCache;
      try {
        final job = Job<Map, String>(
          _Commands.loadImageCache,
          (v) => _Commands.loadImageCache,
          {
            _ArgumentKeys.command: _Commands.loadImageCache,
            _ArgumentKeys.ttl: ttl.inMilliseconds,
            _ArgumentKeys.maxSize: maxSizeInBytes,
            _ArgumentKeys.cachePath: (await cacheStorageResolver()).path
          },
          deduplicationKey: _Commands.loadImageCache,
          cancelled: null,
        );
        final results = _executor.submitAll(job);
        final themeKey = await results[0];
        completer.complete(
            StorageImageCache.withKey(themeKey: themeKey, delegate: cache));
      } catch (e, stack) {
        completer.completeError(e, stack);
      }
      _imageCache = imageCache;
    }
    return await imageCache;
  }

  Future _fillCache(TileCoordinates coords, double tileSize,
      bool Function() cancelled) async {
    final tileArguments = {
      _ArgumentKeys.command: _Commands.render,
      _ArgumentKeys.z: coords.z,
      _ArgumentKeys.x: coords.x,
      _ArgumentKeys.y: coords.y,
      _ArgumentKeys.size: tileSize
    };
    final key = coords.toTileIdentity().key();
    await _executor.submit(Job<Map, String>(
      key,
      (v) => key,
      tileArguments,
      deduplicationKey: key,
      cancelled: cancelled,
    ));
  }
}

class _ArgumentKeys {
  static const command = 'command';
  static const z = 'z';
  static const x = 'x';
  static const y = 'y';
  static const size = 'size';
  static const ttl = 'ttl';
  static const maxSize = 'maxSize';
  static const cachePath = 'cachePath';
}

const _defaultTtl = Duration(days: 30);
const _defaultMaxSizeInBytes = 1024 * 1024 * 200;

class _Commands {
  static const render = 'render';
  static const loadImageCache = 'loadImageCache';
}

class _IsolateTileRenderer {
  final StyleFunction _styleFunction;
  Future<Style>? _style;
  Future<TileLoader>? _tileLoader;
  Caches? _caches;
  String? _cachePath;
  Duration _ttl = _defaultTtl;
  int _maxSizeInBytes = _defaultMaxSizeInBytes;

  _IsolateTileRenderer({required StyleFunction styleFunction})
      : _styleFunction = styleFunction;
  Future accept(dynamic message) async {
    try {
      return await _accept(message);
    } catch (e, stack) {
      // ignore: avoid_print
      print(e);
      // ignore: avoid_print
      print(stack);
      rethrow;
    }
  }

  Future _accept(dynamic message) async {
    final args = message as Map;
    final command = message[_ArgumentKeys.command] as String;
    if (command == _Commands.loadImageCache) {
      _ttl = Duration(milliseconds: args[_ArgumentKeys.ttl] as int);
      _maxSizeInBytes = args[_ArgumentKeys.maxSize] as int;
      _cachePath = args[_ArgumentKeys.cachePath] as String;
      final tileLoader = await _loadTileLoader();
      return tileLoader.imageCache.themeKey;
    } else if (command == _Commands.render) {
      final coords = TileCoordinates(args[_ArgumentKeys.x] as int,
          args[_ArgumentKeys.y] as int, args[_ArgumentKeys.z] as int);
      final tileSize = args[_ArgumentKeys.size] as double;
      return await _renderTile(coords, tileSize);
    } else {
      throw Exception('Unexpected command: $command');
    }
  }

  Future<String> _renderTile(TileCoordinates coords, double tileSize) async {
    final tileLoader = await _loadTileLoader();
    final imageInfo = await tileLoader.loadTile(coords, tileSize, () => false);
    imageInfo.image.dispose();
    return coords.toTileIdentity().key();
  }

  Future<TileLoader> _loadTileLoader() async {
    Future<TileLoader>? tileLoader = _tileLoader;
    if (tileLoader == null) {
      final completer = Completer<TileLoader>();
      tileLoader = completer.future;
      _tileLoader = completer.future;
      try {
        final style = await _loadStyle();
        _caches?.dispose();
        _caches = null;
        final executor = ConcurrencyExecutor(
            delegate: ImmediateExecutor(),
            concurrencyLimit: 2,
            maxQueueSize: 1000);
        Caches caches = Caches(
            providers: style.providers,
            executor: executor,
            theme: style.theme,
            sprites: style.sprites,
            ttl: _ttl,
            memoryTileCacheMaxSize: VectorTileLayer.defaultTileCacheMaxSize,
            memoryTileDataCacheMaxSize:
                VectorTileLayer.defaultTileDataCacheMaxSize,
            maxSizeInBytes: _maxSizeInBytes,
            maxTextCacheSize: VectorTileLayer.defaultTextCacheMaxSize,
            cacheStorage:
                IoByteStorage(pather: () async => Directory(_cachePath!)));
        _caches = caches;
        final rasterTileProvider = RasterTileProvider(
            providers: style.providers, cache: caches.imageLoadingCache);
        final loader = createTileLoader(style.theme, style.sprites, caches,
            rasterTileProvider, executor, TileOffset.DEFAULT, Duration.zero, 2);
        completer.complete(loader);
        tileLoader = completer.future;
      } catch (e, stack) {
        completer.completeError(e, stack);
        _tileLoader = null;
        rethrow;
      }
    }
    return await tileLoader;
  }

  Future<Style> _loadStyle() async {
    Future<Style>? style = _style;
    if (style == null) {
      final completer = Completer<Style>();
      style = completer.future;
      _style = style;
      try {
        final style = await _styleFunction();
        completer.complete(style);
      } catch (e, stack) {
        completer.completeError(e, stack);
        _style = null;
      }
    }
    return await style;
  }
}
