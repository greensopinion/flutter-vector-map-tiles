import 'dart:async';
import 'dart:ui';

import 'package:executor_lib/executor_lib.dart';
import 'package:flutter_map/flutter_map.dart' hide TileProvider;
import 'package:test/test.dart';
import 'package:vector_map_tiles/src/raster/storage_image_cache.dart';
import 'package:vector_map_tiles/src/raster/tile_loader.dart';
import 'package:vector_map_tiles/src/stream/tile_supplier.dart';
import 'package:vector_map_tiles/src/stream/tile_supplier_raster.dart';
import 'package:vector_map_tiles/src/tile_identity.dart';
import 'package:vector_map_tiles/src/tile_offset.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart' hide TileLayer;

void main() {
  late _FakeTileProvider provider;
  late _FakeRasterTileProvider rasterTileProvider;
  late TileLoader loader;
  var cancelled = false;

  setUp(() {
    cancelled = false;
    provider = _FakeTileProvider();
    rasterTileProvider = _FakeRasterTileProvider();
    loader = TileLoader(
        ThemeReader().read({'id': 'a-theme', 'layers': <dynamic>[]}),
        null,
        null,
        provider,
        rasterTileProvider,
        TileOffset.DEFAULT,
        _FakeStorageImageCache(),
        1);
  });

  /// Runs [body] and returns every error that escaped to the zone as
  /// unhandled, after letting pending microtasks and timers run.
  Future<List<Object>> unhandledErrors(Future<void> Function() body) async {
    final errors = <Object>[];
    final done = Completer<void>();
    runZonedGuarded(() async {
      await body();
      await Future<void>.delayed(Duration.zero);
      done.complete();
    }, (error, _) => errors.add(error));
    await done.future;
    return errors;
  }

  Future<void> untilRequested() async {
    while (provider.pending == null || rasterTileProvider.pending == null) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  test('cancellation while the raster tile loads leaves no unhandled error',
      () async {
    final errors = await unhandledErrors(() async {
      final image = loader.loadTile(
          const TileCoordinates(1, 2, 3), TileLayer(), () => cancelled);
      await untilRequested();
      cancelled = true;
      provider.pending!.completeError(CancellationException());
      await Future<void>.delayed(Duration.zero);
      rasterTileProvider.pending!.complete(RasterTileset(tiles: {}));
      await expectLater(image, throwsA(isA<CancellationException>()));
    });
    expect(errors, isEmpty);
  });

  test('a failed raster tile load leaves no unhandled error', () async {
    final errors = await unhandledErrors(() async {
      final image = loader.loadTile(
          const TileCoordinates(1, 2, 3), TileLayer(), () => cancelled);
      await untilRequested();
      rasterTileProvider.pending!.completeError('raster failed');
      await expectLater(image, throwsA('raster failed'));
      provider.pending!.completeError(CancellationException());
    });
    expect(errors, isEmpty);
  });
}

class _FakeTileProvider implements TileProvider {
  Completer<TileResponse>? pending;

  @override
  int get maximumZoom => 14;

  @override
  Future<TileResponse> provide(TileRequest request) {
    final completer = Completer<TileResponse>();
    pending = completer;
    return completer.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeRasterTileProvider implements RasterTileProvider {
  Completer<RasterTileset>? pending;

  @override
  Future<RasterTileset> retrieve(TileIdentity tile, {bool skipMissing = true}) {
    final completer = Completer<RasterTileset>();
    pending = completer;
    return completer.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeStorageImageCache implements StorageImageCache {
  @override
  Future<Image?> retrieve(TileIdentity tile) => Future.value(null);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
