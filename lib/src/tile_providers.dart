import '../vector_map_tiles.dart';

/// provides [VectorTileProvider] by source ID, where the source ID corresponds
/// to a `source` in the theme
class TileProviders {
  /// provides vector tiles, by source ID where the source ID corresponds to
  /// a source in the theme
  final Map<String, VectorTileProvider> tileProviderBySource;

  const TileProviders(this.tileProviderBySource);

  VectorTileProvider get(String source) {
    final provider = tileProviderBySource[source];
    if (provider == null) {
      throw 'no VectorTileProvider for source $source';
    }
    return provider;
  }
}
