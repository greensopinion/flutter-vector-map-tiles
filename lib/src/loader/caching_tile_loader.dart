import 'package:executor_lib/executor_lib.dart';
import '../cache/cache_tiered.dart';
import 'default_tile_loader.dart';
import 'theme_repo.dart';
import 'tile_loader.dart';
import '../model/map_properties.dart';

TileLoader createCachingTileLoader(
  MapProperties mapProperties,
  Executor executor,
  ThemeRepo themeRepo,
) =>
    DefaultTileLoader(
      tileSize: 256.0,
      mapProperties: mapProperties,
      executor: executor,
      cache: CacheTiered(properties: mapProperties.cacheProperties),
      themeRepo: themeRepo,
    );
