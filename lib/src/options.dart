import 'package:flutter_map/plugin_api.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../vector_map_tiles.dart';

enum RenderMode {
  /// tiles are rendered using vectors only
  vector,

  /// tiles are rendered using vectors when idle, and raster images when
  /// zooming. Can improve the frame rate and reduce jank.
  mixed,

  /// tiles are rendered using raster images only
  /// raster images are created by rendering the vector tile to an image
  raster
}

/// a [FlutterMap] layer options, to be used with [VectorMapTilesPlugin].
/// See the readme for details.
/// See [VectorTileLayerWidget] for an alternative.
class VectorTileLayerOptions extends LayerOptions {
  /// provides vector tiles, by source ID where the source ID corresponds to
  /// a source in the theme
  final TileProviders tileProviders;

  /// the theme used to render tiles
  final Theme theme;

  /// determines how tiles are rendered to the canvas.
  /// `vector` - exclusively uses vector rendering. Produces the sharpest map
  /// images.
  /// `mixed` - uses raster tiles while zooming and renders using vectors when
  /// idle. Makes for smooth animations while the user interacts with the map
  /// and reduces CPU overhead.
  final RenderMode renderMode;

  /// the scale of raster images when using `mixed` [renderMode].
  /// best quality corresponds to the device pixel ratio, at the expense of
  /// memory. Set to 1.0 to have lowest memory usage.
  final double rasterImageScale;

  /// the time to live of items in the file cache
  /// consider the terms of your tile provider service
  /// and the desired freshness of map data when setting this value
  final Duration fileCacheTtl;
  static const DEFAULT_CACHE_TTL = Duration(days: 30);

  /// the maximum size of the file-based cache in bytes.
  /// the cache does a good-enough effort to keep the cache size
  /// within the specified limit, however the size can exceed the
  /// specified limit from time to time.
  final fileCacheMaximumSizeInBytes;
  static const DEFAULT_CACHE_MAX_SIZE = 50 * 1024 * 1024;

  /// The maximum number of images retained in the memory
  /// cache.
  /// The higher the number of images retained in memory,
  /// the less the user is exposed to delays in loading tiles
  /// and therefore the less flicker on the map. Images
  /// take anywhere from 2-3MB each, so setting this value too
  /// high can result in exceeding maximum allowable process memory
  /// size, resulting in the OS terminating the app (i.e. crashes).
  /// Only applicable for [renderMode] of `mixed` or `raster`.
  final int maxImagesInMemory;
  static const DEFAULT_CACHE_MAX_IMAGES_IN_MEMORY = 0;

  /// The maximum number of decoded vector tiles retained in the memory
  /// vector tile cache.
  /// Cached vector tiles eliminate the need to decode protobuf tile data.
  /// Deprecated: no longer used, see [memoryTileCacheMaxSize] instead
  @deprecated
  final int maxTilesInMemory;

  /// Deprecated: no longer used, see [DEFAULT_TILE_CACHE_MAX_SIZE] instead
  @deprecated
  static const DEFAULT_CACHE_MAX_TILES_IN_MEMORY = 50;

  /// The maximum size in bytes of the memory vector tile cache.
  final int memoryTileCacheMaxSize;
  static const DEFAULT_TILE_CACHE_MAX_SIZE = 1024 * 1024 * 10;

  /// Indicates whether debug information should be shown for tiles
  final bool showTileDebugInfo;

  /// Indicates whether to log cache stats
  final bool logCacheStats;

  /// Draws background from a vector tile source when available
  final Theme? backgroundTheme;

  /// The delay that should be applied to tile loading, useful for
  /// slowing down the map to observe how it behaves as tiles are loading
  final Duration tileDelay;

  VectorTileLayerOptions(
      {required this.tileProviders,
      required this.theme,
      this.rasterImageScale = 3.0,
      this.renderMode = RenderMode.mixed,
      this.fileCacheTtl = DEFAULT_CACHE_TTL,
      this.maxTilesInMemory = 0,
      this.memoryTileCacheMaxSize = DEFAULT_TILE_CACHE_MAX_SIZE,
      this.maxImagesInMemory = DEFAULT_CACHE_MAX_IMAGES_IN_MEMORY,
      this.fileCacheMaximumSizeInBytes = DEFAULT_CACHE_MAX_SIZE,
      this.backgroundTheme,
      this.showTileDebugInfo = false,
      this.logCacheStats = false,
      this.tileDelay = const Duration(milliseconds: 0)}) {
    assert(rasterImageScale >= 1.0 && rasterImageScale <= 5.0);
    assert(maxImagesInMemory >= 0 && maxImagesInMemory <= 200);
  }
}
