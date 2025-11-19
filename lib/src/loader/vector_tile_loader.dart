import 'dart:typed_data';

import 'package:executor_lib/executor_lib.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../../vector_map_tiles.dart';
import '../cache/cache.dart';
import '../model/map_properties.dart';
import '../tile_translation.dart';
import 'theme_repo.dart';
import 'vector_tile_transform.dart';

class VectorTileLoader {
  final double tileSize;
  final MapProperties mapProperties;
  final Cache cache;
  late final VectorTileTransform transform;
  final Executor executor;
  final ThemeRepo themeRepo;

  VectorTileLoader({
    required this.tileSize,
    required this.mapProperties,
    required this.executor,
    required this.cache,
    required this.themeRepo,
  }) {
    transform = VectorTileTransform(
        executor: executor,
        theme: mapProperties.theme,
        tileSize: tileSize,
        themeRepo: themeRepo);
  }

  Future<Tileset> load(TileIdentity tile, bool Function() cancelled) async {
    final sourceTiles = mapProperties.theme.tileSources
        .map(
          (source) => MapEntry(source, mapProperties.tileProviders.get(source)),
        )
        .where((e) => e.value.type == TileProviderType.vector)
        .map((e) => _load(e.key, e.value, tile, cancelled));
    final tilesBySource = <String, Tile>{};
    for (final sourceTileFuture in sourceTiles) {
      final sourceTile = await sourceTileFuture;
      final tile = sourceTile.tile;
      if (tile != null) {
        tilesBySource[sourceTile.source] = tile;
      }
    }
    return Tileset(tilesBySource);
  }

  TileData _emptyTile() => TileFactory(
        mapProperties.theme,
        const Logger.noop(),
      ).createTileData(VectorTile(layers: []));

  Future<_SourceTile> _load(
    String source,
    VectorTileProvider provider,
    TileIdentity tile,
    bool Function() cancelled,
  ) async {
    if (tile.z < provider.minimumZoom) {
      return _SourceTile(source: source, tile: _emptyTile().toTile());
    }
    var translation = SlippyMapTranslator(provider.maximumZoom).translate(tile);
    final tileToLoad = translation.translated;
    final themeKey = mapProperties.theme.id;
    final cacheKey =
        '${themeKey}_${source}_${tileToLoad.z}_${tileToLoad.x}_${tileToLoad.y}.pbf';
    final Uint8List bytes;
    try {
      bytes = await cache.get(
        cacheKey,
        load: (key) => provider.provide(tileToLoad),
      );
    } on ProviderException catch (error) {
      if (error.statusCode == 404 || error.statusCode == 204) {
        return _SourceTile(source: source, tile: _emptyTile().toTile());
      }
      rethrow;
    }
    if (cancelled()) {
      throw CancellationException();
    }
    final transformed = await transform.apply(
        bytes, translation, cancelled, source, mapProperties.tileOffset);
    return _SourceTile(source: source, tile: transformed);
  }
}

class _SourceTile {
  final String source;
  final Tile? tile;

  _SourceTile({required this.source, required this.tile});
}
