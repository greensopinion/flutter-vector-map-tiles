import 'package:flutter_map/plugin_api.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../vector_map_tiles.dart';

/// a [FlutterMap] layer options, to be used with [VectorMapTilesPlugin].
/// See the readme for details.
/// See [VectorTileLayerWidget] for an alternative.
class VectorTileLayerOptions extends LayerOptions {
  /// provides vector tiles, by source ID where the source ID corresponds to
  /// a source in the theme
  final TileProviders tileProviders;

  /// the theme used to render tiles
  final Theme theme;

  /// the time to live of items in the file cache
  /// consider the terms of your tile provider service
  /// and the desired freshness of map data when setting this value
  final Duration fileCacheTtl;

  /// the default [fileCacheTtl]
  static const DEFAULT_CACHE_TTL = Duration(days: 30);

  /// the maximum size of the file-based cache in bytes.
  /// the cache does a good-enough effort to keep the cache size
  /// within the specified limit, however the size can exceed the
  /// specified limit from time to time.
  final fileCacheMaximumSizeInBytes;

  /// the default [fileCacheMaximumSizeInBytes]
  static const DEFAULT_CACHE_MAX_SIZE = 50 * 1024 * 1024;

  /// The maximum size in bytes of the memory vector tile cache.
  final int memoryTileCacheMaxSize;

  /// the default [memoryTileCacheMaxSize]
  static const DEFAULT_TILE_CACHE_MAX_SIZE = 1024 * 1024 * 10;

  /// The maximum size of the text cache.
  final int textCacheMaxSize;

  /// the default [textCacheMaxSize]
  static const DEFAULT_TEXT_CACHE_MAX_SIZE = 100;

  /// Indicates whether debug information should be shown for tiles
  final bool showTileDebugInfo;

  /// Indicates whether to log cache stats
  final bool logCacheStats;

  /// Draws background from a vector tile source when available
  final Theme? backgroundTheme;

  /// The delay that should be applied to tile loading, useful for
  /// slowing down the map to observe how it behaves as tiles are loading
  final Duration tileDelay;

  /// The level of concurrency to use, must be >= 0.
  /// When set to 1 or higher, [isolates](https://dart.dev/guides/language/concurrency)
  /// are used for computations to offload expensive operations from the UI thread.
  /// This setting has no effect in debug mode.
  final int concurrency;

  /// The default [concurrency] to use.
  static const DEFAULT_CONCURRENCY = 2;

  /// The tile offset, defaults to [TileOffset.DEFAULT].
  /// See [TileOffset.mapbox]
  final TileOffset tileOffset;

  VectorTileLayerOptions(
      {required this.tileProviders,
      required this.theme,
      this.fileCacheTtl = DEFAULT_CACHE_TTL,
      this.memoryTileCacheMaxSize = DEFAULT_TILE_CACHE_MAX_SIZE,
      this.fileCacheMaximumSizeInBytes = DEFAULT_CACHE_MAX_SIZE,
      this.textCacheMaxSize = DEFAULT_TEXT_CACHE_MAX_SIZE,
      this.concurrency = DEFAULT_CONCURRENCY,
      this.tileOffset = TileOffset.DEFAULT,
      this.backgroundTheme,
      this.showTileDebugInfo = false,
      this.logCacheStats = false,
      this.tileDelay = const Duration(milliseconds: 0)}) {
    assert(concurrency >= 0 && concurrency <= 100);
  }
}

/// Describes a tile size and zoom offset so that loaded tiles can be used to
/// render a larger or smaller area.
class TileOffset {
  /// [zoomOffset] the zoom offset, usually 0. A negative offset will cause tiles
  /// to be loaded at a lower zoom level than normal. E.g. a zoomOffset of -1 will
  /// cause the map to load tiles at zoom level 13 when the map is at zoom level 14.
  final int zoomOffset;

  const TileOffset({required this.zoomOffset});

  /// The default tile offset with size 256.0 and zoomOffset 0
  static const DEFAULT = const TileOffset(zoomOffset: 0);

  /// A tile offset corresponding to that recommended by Mapbox
  /// https://docs.mapbox.com/help/glossary/zoom-level/#tile-size
  static final mapbox = DEFAULT.offsetBy(zoom: -1);

  /// provides an offset relative to this one.
  ///
  /// [zoom] the zoom of the offset. For example, for a tile size of 256 and
  ///         offset of 0, providing a [zoom] of -1 will produce an offset with
  ///         tile size 512 and zoomOffset of -1
  TileOffset offsetBy({required int zoom}) {
    if (zoom == 0) {
      return this;
    }
    assert(zoom < 0);

    return TileOffset(zoomOffset: zoomOffset + zoom);
  }
}
