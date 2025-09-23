import 'package:executor_lib/executor_lib.dart';
import 'package:vector_map_tiles/src/cache/cache_memory.dart';
import 'package:vector_map_tiles/src/cache/cache_tiered.dart';
import 'package:vector_map_tiles/src/loader/default_tile_loader.dart';
import 'package:vector_map_tiles/src/loader/theme_repo.dart';
import 'package:vector_map_tiles/src/loader/tile_loader.dart';
import 'package:vector_map_tiles/src/model/map_properties.dart';

TileLoader createCachingTileLoader(
  MapProperties mapProperties,
  Executor executor,
  ThemeRepo themeRepo
) => DefaultTileLoader(
  tileSize: 256.0,
  mapProperties: mapProperties,
  executor: executor,
  cache: CacheMemory(properties: mapProperties.cacheProperties),
  themeRepo: themeRepo
);
