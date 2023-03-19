import 'package:executor_lib/executor_lib.dart';
import 'package:flutter/material.dart' hide Theme, ImageCache;
import 'package:flutter/widgets.dart' hide ImageCache;
import 'package:flutter_map/plugin_api.dart';
import 'package:vector_map_tiles/src/raster/storage_image_cache.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../../vector_map_tiles.dart';
import '../cache/caches.dart';
import '../stream/caches_tile_provider.dart';
import '../stream/delay_provider.dart';
import '../stream/tile_processor.dart';
import '../stream/tileset_executor_preprocessor.dart';
import '../stream/tileset_ui_preprocessor.dart';
import '../stream/translating_tile_provider.dart';
import 'future_tile_provider.dart';
import 'tile_loader.dart';

/// Provides a [TileProvider] for use with [FlutterMap].
///
class RasterTileState extends StatefulWidget {
  /// provides vector tiles, by source ID where the source ID corresponds to
  /// a source in the theme
  final TileProviders tileProviders;

  /// the theme used to render tiles
  final Theme theme;

  /// the time to live of items in the file cache
  /// consider the terms of your tile provider service
  /// and the desired freshness of map data when setting this value
  final Duration fileCacheTtl;

  /// the maximum size of the file-based cache in bytes.
  /// the cache does a good-enough effort to keep the cache size
  /// within the specified limit, however the size can exceed the
  /// specified limit from time to time.
  final int fileCacheMaximumSizeInBytes;

  /// The maximum size in bytes of the memory vector tile cache.
  final int memoryTileCacheMaxSize;

  /// The maximum size in tiles of the memory vector tile cache.
  /// Differs from [memoryTileCacheMaxSize] in that this is the cache
  /// of parsed vector tiles, whereas [memoryTileCacheMaxSize] is the raw
  /// tile data.
  final int memoryTileDataCacheMaxSize;

  /// The maximum size of the text cache.
  final int textCacheMaxSize;

  /// The delay that should be applied to tile loading, useful for
  /// slowing down the map to observe how it behaves as tiles are loading
  final Duration tileDelay;

  /// The level of concurrency to use, must be >= 0.
  /// When set to 1 or higher, [isolates](https://dart.dev/guides/language/concurrency)
  /// are used for computations to offload expensive operations from the UI thread.
  /// This setting has no effect in debug mode.
  final int concurrency;

  final Widget Function(BuildContext context, TileProvider tileProvider)
      builder;

  const RasterTileState(
      {super.key,
      required this.tileProviders,
      required this.theme,
      this.fileCacheTtl = VectorTileLayer.defaultCacheTtl,
      this.memoryTileCacheMaxSize = VectorTileLayer.defaultTileCacheMaxSize,
      this.memoryTileDataCacheMaxSize =
          VectorTileLayer.defaultTileDataCacheMaxSize,
      this.fileCacheMaximumSizeInBytes = VectorTileLayer.defaultCacheMaxSize,
      this.textCacheMaxSize = VectorTileLayer.defaultTextCacheMaxSize,
      this.concurrency = VectorTileLayer.defaultConcurrency,
      this.tileDelay = const Duration(milliseconds: 0),
      required this.builder});

  @override
  State<StatefulWidget> createState() => _RasterTileState();
}

class _RasterTileState extends State<RasterTileState> {
  late FutureTileProvider tileProvider;
  late Caches _caches;
  late Executor _executor;

  @override
  void initState() {
    super.initState();
    _executor = newExecutor(concurrency: widget.concurrency);
    _initializeTileProvider();
    Future.delayed(const Duration(seconds: 3), () {
      _caches.applyConstraints();
    });
    _initializeTileProvider();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, tileProvider!);
  }

  @override
  void dispose() {
    super.dispose();
    _executor.dispose();
  }

  @override
  void didUpdateWidget(RasterTileState oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.theme != widget.theme) {
      setState(() {
        _initializeTileProvider();
      });
    }
  }

  void _initializeTileProvider() {
    _caches = Caches(
        executor: _executor,
        providers: widget.tileProviders,
        theme: widget.theme,
        ttl: widget.fileCacheTtl,
        memoryTileCacheMaxSize: widget.memoryTileCacheMaxSize,
        memoryTileDataCacheMaxSize: widget.memoryTileDataCacheMaxSize,
        maxSizeInBytes: widget.fileCacheMaximumSizeInBytes,
        maxTextCacheSize: widget.textCacheMaxSize);
    final tileSupplier = TranslatingTileProvider(DelayProvider(
            CachesTileProvider(
                _caches,
                TileProcessor(_executor),
                TilesetExecutorPreprocessor(
                    TilesetPreprocessor(widget.theme), _executor),
                TilesetUiPreprocessor(TilesetPreprocessor(widget.theme,
                    initializeGeometry: true))),
            widget.tileDelay)
        .orDelegate());
    tileProvider = FutureTileProvider(
        loader: TileLoader(widget.theme, tileSupplier,
                StorageImageCache(widget.theme, _caches.storageCache))
            .loadTile);
  }
}
