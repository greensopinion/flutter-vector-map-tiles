import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../../vector_map_tiles.dart';
import '../cache/cache.dart';

class MapProperties {
  final TileProviders tileProviders;

  final Theme theme;

  final TileOffset tileOffset;

  final CacheProperties cacheProperties;

  final int concurrency;

  final SpriteStyle? sprites;

  const MapProperties({
    required this.tileProviders,
    required this.theme,
    required this.tileOffset,
    required this.concurrency,
    required this.cacheProperties,
    this.sprites,
  });
}
