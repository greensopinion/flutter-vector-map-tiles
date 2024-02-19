import 'dart:typed_data';

import 'package:pmtiles/pmtiles.dart';

import '../../vector_map_tiles.dart';
import '../provider_exception.dart';

/// A network tile provider that uses HTTP range requests with
/// a [pmtiles archive](https://docs.protomaps.com/pmtiles/).
/// A [PmTilesProvider] is stateful since it must load the pmtiles
/// index before loading any tiles.
///
/// Instances of [PmTilesArchive] should
/// be long-lived to reduce network calls, and [PmTilesArchive.close] must be called
/// do release resources when it is no longer needed.
class PmTilesProvider extends VectorTileProvider {
  PmTilesArchive archive;
  @override
  final TileProviderType type;

  @override
  final int maximumZoom;
  @override
  final int minimumZoom;

  PmTilesProvider(
      {required this.archive,
      required this.type,
      required this.minimumZoom,
      required this.maximumZoom});

  @override
  Future<Uint8List> provide(TileIdentity tile) async {
    _checkZoom(archive, tile);
    final tileId = ZXY(tile.z, tile.x, tile.y).toTileId();
    try {
      final t = await archive.tile(tileId);
      return Uint8List.fromList(t.bytes());
    } catch (e) {
      if (e is TileNotFoundException) {
        throw ProviderException(
            message: 'not found: $tile',
            retryable: Retryable.none,
            statusCode: 404);
      }
      rethrow;
    }
  }

  void _checkZoom(PmTilesArchive archive, TileIdentity tile) {
    if (tile.z < archive.header.minZoom || tile.z > archive.header.maxZoom) {
      throw ProviderException(
          message:
              '${tile.z} must be in [${archive.header.minZoom}..${archive.header.maxZoom}]',
          retryable: Retryable.none);
    }
  }
}
