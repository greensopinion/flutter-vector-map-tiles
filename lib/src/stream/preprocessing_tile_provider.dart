import 'tile_supplier.dart';
import '../tile_identity.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

class PreprocessingTileProvider extends TileProvider {
  final TileProvider _delegate;
  final TilesetPreprocessor _preprocessor;

  PreprocessingTileProvider(this._delegate, this._preprocessor);

  @override
  int get maximumZoom => _delegate.maximumZoom;

  @override
  Future<Tile> provide(TileIdentity tileIdentity, TileFormat format,
      {double? zoom}) async {
    final tile = await _delegate.provide(tileIdentity, format, zoom: zoom);
    return _preprocess(tile);
  }

  Future<Tile> _preprocess(Tile tile) async {
    if (tile.tileset != null) {
      return Tile(
          identity: tile.identity,
          format: tile.format,
          tileset: _preprocessor.preprocess(tile.tileset!));
    }
    return tile;
  }
}
