part of "vector_tile_provider.dart";

/// [assetPathTemplate] the asset path template, e.g. `'assets/map_tiles/{z}/{x}/{y}.pbf'`
/// [maximumZoom] the maximum zoom supported by the tile provider, not to be
/// confused with the maximum zoom of the map widget. The map widget will
/// automatically use vector tiles from lower zoom levels once the maximum
/// supported by this provider is reached.
class AssetVectorTileProvider extends VectorTileProvider {
  AssetVectorTileProvider({required String assetPathTemplate, int maximumZoom = 16}) 
    : _maximumZoom = maximumZoom, 
      _uriProvider = _UriProvider(assetPathTemplate);

  final int _maximumZoom;
  final _UriProvider _uriProvider;

  @override
  int get maximumZoom => _maximumZoom;

  @override
  Future<Uint8List> provide(TileIdentity tile) {
    final uri =_uriProvider.uri(tile);

    return rootBundle.load(uri).then((value) => value.buffer.asUint8List());
  }
}
