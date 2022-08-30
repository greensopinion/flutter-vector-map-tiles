// ignore_for_file: constant_identifier_names

import 'package:flutter_map/plugin_api.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import './extensions.dart';
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
  final int fileCacheMaximumSizeInBytes;

  /// the default [fileCacheMaximumSizeInBytes]
  static const DEFAULT_CACHE_MAX_SIZE = 50 * 1024 * 1024;

  /// The maximum size in bytes of the memory vector tile cache.
  final int memoryTileCacheMaxSize;

  /// the default [memoryTileCacheMaxSize]
  static const DEFAULT_TILE_CACHE_MAX_SIZE = 1024 * 1024 * 10;

  /// The maximum size in tiles of the memory vector tile cache.
  /// Differs from [memoryTileCacheMaxSize] in that this is the cache
  /// of parsed vector tiles, whereas [memoryTileCacheMaxSize] is the raw
  /// tile data.
  final int memoryTileDataCacheMaxSize;

  /// the default [memoryTileDataCacheMaxSize]
  static const DEFAULT_TILE_DATA_CACHE_MAX_SIZE = 20;

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

  /// The maximum zoom difference when substituting tiles while overlapping tiles
  /// are loading. A higher zoom difference results in lower chance of a blank map
  /// while loading tiles to display. A larger zoom difference requires more
  /// memory and can result in an application exceeding available memory, resulting
  /// in a crash. To avoid substituting tiles, use a value of 0.
  final int maximumTileSubstitutionDifference;

  /// the default [maximumTileSubstitutionDifference]
  static const DEFAULT_MAX_TILE_SUBSTITUTION_DIFFERENCE = 2;

  /// The default [concurrency]
  static const DEFAULT_CONCURRENCY = 4;

  /// The tile offset, defaults to [TileOffset.DEFAULT].
  /// See [TileOffset.mapbox]
  final TileOffset tileOffset;

  VectorTileLayerOptions(
      {required this.tileProviders,
      required this.theme,
      this.fileCacheTtl = DEFAULT_CACHE_TTL,
      this.memoryTileCacheMaxSize = DEFAULT_TILE_CACHE_MAX_SIZE,
      this.memoryTileDataCacheMaxSize = DEFAULT_TILE_DATA_CACHE_MAX_SIZE,
      this.fileCacheMaximumSizeInBytes = DEFAULT_CACHE_MAX_SIZE,
      this.textCacheMaxSize = DEFAULT_TEXT_CACHE_MAX_SIZE,
      this.concurrency = DEFAULT_CONCURRENCY,
      this.tileOffset = TileOffset.DEFAULT,
      this.maximumTileSubstitutionDifference =
          DEFAULT_MAX_TILE_SUBSTITUTION_DIFFERENCE,
      this.backgroundTheme,
      this.showTileDebugInfo = false,
      this.logCacheStats = false,
      this.tileDelay = const Duration(milliseconds: 0)}) {
    assert(concurrency >= 0 && concurrency <= 100);
    final providers = theme.tileSources
        .map((source) => tileProviders.tileProviderBySource[source])
        .whereType<VectorTileProvider>();
    assert(
        providers.isNotEmpty,
        '''
tileProviders must provide at least one provider that matches the given theme. 
Usually this is an indication that TileProviders in the code doesn't match the sources
required by the theme. 
The theme uses the following sources: ${theme.tileSources.toList().sorted().join(', ')}.
'''
            .trim());
    assert(
        maximumTileSubstitutionDifference >= 0 &&
            maximumTileSubstitutionDifference <= 3,
        'maximumTileSubstitutionDifference must be >= 0 and <= 3');
    assert(memoryTileDataCacheMaxSize >= 0 && memoryTileDataCacheMaxSize < 100);
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
  static const DEFAULT = TileOffset(zoomOffset: 0);

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
