import 'dart:typed_data';

import 'package:executor_lib/executor_lib.dart';
import 'package:vector_tile_dem/vector_tile_dem.dart';

import '../tile_identity.dart';
import '../tile_offset.dart';
import '../vector_tile_provider.dart';

class RasterDemVectorTileProvider extends VectorTileProvider {
  final VectorTileProvider delegate;
  final Executor executor;
  final ContourOptions Function({required int zoom}) options;
  RasterDemVectorTileProvider(
      {required this.delegate, required this.executor, required this.options});

  @override
  int get maximumZoom => delegate.maximumZoom;
  @override
  int get minimumZoom => delegate.minimumZoom;
  @override
  TileOffset get tileOffset => delegate.tileOffset;

  @override
  Future<Uint8List> provide(TileIdentity tile) async {
    return terrariumToContourLines(
        tile: tile.toTileId(),
        demProvider: _DemProviderAdapter(delegate: delegate),
        options: options(zoom: tile.z),
        executor: executor);
  }
}

extension _TileIdentityExtension on TileIdentity {
  TileId toTileId() => TileId(z: z, x: x, y: y);
}

extension _TileIdExtension on TileId {
  TileIdentity toTileIdentity() => TileIdentity(z, x, y);
}

class _DemProviderAdapter extends DemProvider {
  final VectorTileProvider delegate;

  _DemProviderAdapter({required this.delegate});

  @override
  int get maxZoom => delegate.maximumZoom;

  @override
  Future<Uint8List> provide({required TileId tile}) =>
      delegate.provide(tile.toTileIdentity());
}
