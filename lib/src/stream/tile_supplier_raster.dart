import 'dart:ui';

import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../../vector_map_tiles.dart';
import '../cache/image_loading_cache.dart';
import '../grid/slippy_map_translator.dart';

class RasterTileProvider {
  final TileProviders _providers;
  final ImageLoadingCache _cache;

  RasterTileProvider(
      {required TileProviders providers, required ImageLoadingCache cache})
      : _providers = providers,
        _cache = cache;

  Future<RasterTileset> retrieve(TileIdentity tile,
      {bool skipMissing = false}) async {
    final rasterProviders = _providers.tileProviderBySource.entries
        .where((e) => e.value.type == TileProviderType.raster);
    final tileFutureByKey = rasterProviders
        .map((e) => MapEntry(e.key, _loadRasterTile(e.key, tile, e.value)));
    final tileBySource = <String, RasterTile>{};
    for (final futureEntry in tileFutureByKey) {
      try {
        final tile = await futureEntry.value;
        if (tile != null) {
          tileBySource[futureEntry.key] = tile;
        }
      } catch (_) {
        if (!skipMissing) {
          RasterTileset(tiles: tileBySource).dispose();
          rethrow;
        }
      }
    }
    return RasterTileset(tiles: tileBySource);
  }

  Future<RasterTile?> _loadRasterTile(
      String key, TileIdentity tile, VectorTileProvider provider) async {
    final zoom = tile.z;
    if (zoom < provider.minimumZoom) {
      return null;
    }
    var translation = TileTranslation.identity(tile.normalize());
    if (zoom > provider.maximumZoom) {
      final translator = SlippyMapTranslator(provider.maximumZoom);
      translation = translator.specificZoomTranslation(translation.original,
          zoom: provider.maximumZoom);
    }
    final image = await _cache.retrieve(key, translation.translated);
    var scope =
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    if (translation.isTranslated) {
      final fraction = translation.fraction;
      final xDimension = scope.width / fraction;
      final yDimension = scope.height / fraction;
      scope = Rect.fromLTWH(xDimension * translation.xOffset,
          yDimension * translation.yOffset, xDimension, yDimension);
    }
    return RasterTile(image: image, scope: scope);
  }
}
