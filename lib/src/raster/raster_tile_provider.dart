import 'package:executor_lib/executor_lib.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../../vector_map_tiles.dart';
import '../cache/caches.dart';
import '../stream/caches_tile_provider.dart';
import '../stream/delay_provider.dart';
import '../stream/tile_processor.dart';
import '../stream/tile_supplier_raster.dart';
import '../stream/tileset_executor_preprocessor.dart';
import '../stream/tileset_ui_preprocessor.dart';
import '../stream/translating_tile_provider.dart';
import 'future_tile_provider.dart';
import 'storage_image_cache.dart';
import 'tile_loader.dart';

TileProvider createRasterTileProvider(
    Theme theme,
    SpriteStyle? sprites,
    Caches caches,
    RasterTileProvider rasterTileProvider,
    Executor executor,
    TileOffset tileOffset,
    Duration tileDelay,
    int concurrency) {
  final tileSupplier = TranslatingTileProvider(DelayProvider(
          CachesTileProvider(
              caches,
              TileProcessor(executor),
              TilesetExecutorPreprocessor(TilesetPreprocessor(theme), executor),
              TilesetUiPreprocessor(
                  TilesetPreprocessor(theme, initializeGeometry: true))),
          tileDelay)
      .orDelegate());
  return FutureTileProvider(
      loader: TileLoader(
              theme,
              sprites,
              caches.atlasImageCache?.retrieve,
              tileSupplier,
              rasterTileProvider,
              tileOffset,
              StorageImageCache(theme, caches.storageCache),
              concurrency)
          .loadTile);
}
