import 'package:flutter_map/plugin_api.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import 'vector_tile_provider.dart';

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

class VectorTileLayerOptions extends LayerOptions {
  /// provides vector tiles
  final VectorTileProvider tileProvider;

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
  /// cache. Only applicable for [renderMode] of `vector`.
  /// The higher the number of images retained in memory,
  /// the less the user is exposed to delays in loading tiles
  /// and therefore the less flicker on the map. Images
  /// take anywhere from 2-3MB each, so setting this value too
  /// high can result in exceeding maximum allowable process memory
  /// size, resulting in the OS terminating the app (i.e. crashes).
  final maxImagesInMemory;
  static const DEFAULT_CACHE_MAX_IMAGES_IN_MEMORY = 80;

  /// Indicates whether debug information should be shown for tiles
  final bool showTileDebugInfo;

  /// Indicates whether to log cache stats
  final bool logCacheStats;

  VectorTileLayerOptions(
      {required this.tileProvider,
      required this.theme,
      this.rasterImageScale = 3.0,
      this.renderMode = RenderMode.mixed,
      this.fileCacheTtl = DEFAULT_CACHE_TTL,
      this.maxImagesInMemory = DEFAULT_CACHE_MAX_IMAGES_IN_MEMORY,
      this.fileCacheMaximumSizeInBytes = DEFAULT_CACHE_MAX_SIZE,
      this.showTileDebugInfo = false,
      this.logCacheStats = false}) {
    assert(rasterImageScale >= 1.0 && rasterImageScale <= 5.0);
    assert(maxImagesInMemory >= 1 && maxImagesInMemory <= 200);
  }
}
