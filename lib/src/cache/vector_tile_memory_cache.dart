import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../tile_identity.dart';
import 'cache.dart';

class TileKey {
  final TileIdentity id;
  final String source;
  TileKey(this.id, this.source);

  @override
  operator ==(o) => o is TileKey && o.id == id && o.source == source;

  @override
  int get hashCode => id.hashCode ^ source.hashCode;

  @override
  String toString() => 'TileKey(id=$id,source=$source)';
}

class VectorTileMemoryCache extends Cache<TileKey, VectorTile> {
  VectorTileMemoryCache(int maxSize)
      : super(maxSize: maxSize, sizer: Sizer(), copier: Copier());
}
