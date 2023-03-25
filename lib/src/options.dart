import 'vector_tile_layer_mode.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import 'tile_offset.dart';
import 'tile_providers.dart';
import 'vector_tile_layer.dart' as vmt;

class VectorTileLayerOptions {
  final TileProviders tileProviders;
  final Theme theme;
  final Duration fileCacheTtl;
  final int fileCacheMaximumSizeInBytes;
  final int memoryTileCacheMaxSize;
  final int memoryTileDataCacheMaxSize;
  final int textCacheMaxSize;
  final bool showTileDebugInfo;
  final bool logCacheStats;
  final Theme? backgroundTheme;
  final Duration tileDelay;
  final int concurrency;
  final int maximumTileSubstitutionDifference;
  final TileOffset tileOffset;
  final VectorTileLayerMode layerMode;
  final double? maximumZoom;

  VectorTileLayerOptions(vmt.VectorTileLayer layer)
      : tileProviders = layer.tileProviders,
        theme = layer.theme,
        fileCacheTtl = layer.fileCacheTtl,
        fileCacheMaximumSizeInBytes = layer.fileCacheMaximumSizeInBytes,
        memoryTileCacheMaxSize = layer.memoryTileCacheMaxSize,
        memoryTileDataCacheMaxSize = layer.memoryTileDataCacheMaxSize,
        textCacheMaxSize = layer.textCacheMaxSize,
        showTileDebugInfo = layer.showTileDebugInfo,
        logCacheStats = layer.logCacheStats,
        backgroundTheme = layer.backgroundTheme,
        tileDelay = layer.tileDelay,
        concurrency = layer.concurrency,
        maximumTileSubstitutionDifference =
            layer.maximumTileSubstitutionDifference,
        tileOffset = layer.tileOffset,
        layerMode = layer.layerMode,
        maximumZoom = layer.maximumZoom;
}
