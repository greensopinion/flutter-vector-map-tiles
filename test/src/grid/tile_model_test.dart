import 'dart:async';
import 'dart:io';

import 'package:executor_lib/executor_lib.dart';
import 'package:test/test.dart';
import 'package:vector_map_tiles/src/grid/tile_model.dart';
import 'package:vector_map_tiles/src/grid/tile_zoom.dart';
import 'package:vector_map_tiles/src/stream/tile_supplier.dart';
import 'package:vector_map_tiles/src/stream/tile_supplier_raster.dart';
import 'package:vector_map_tiles/src/tile_identity.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

void main() {
  final tile = TileIdentity(3, 1, 2);
  late _FakeTileProvider tileProvider;
  late _FakeRasterTileProvider rasterTileProvider;
  late _RecordingRasterTileset rasterTileset;
  late VectorTileModel model;

  setUp(() {
    tileProvider = _FakeTileProvider();
    rasterTileProvider = _FakeRasterTileProvider();
    rasterTileset = _RecordingRasterTileset();
    model = VectorTileModel(
        tileProvider,
        rasterTileProvider,
        ThemeReader().read({'id': 'a-theme', 'layers': <dynamic>[]}),
        null,
        null,
        null,
        tile,
        0,
        TileStateProvider(tile, (_) => 1.0, () => 3.0, () => 3.0, () => 0.0),
        false,
        false);
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
    while (tileProvider.pending == null || rasterTileProvider.pending == null) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  test('loads the tile and the raster tileset', () async {
    final errors = await unhandledErrors(() async {
      model.startLoading();
      await untilRequested();
      tileProvider.pending!
          .complete(TileResponse(identity: tile, tileset: Tileset({})));
      rasterTileProvider.pending!.complete(rasterTileset);
      await Future<void>.delayed(Duration.zero);
    });
    expect(errors, isEmpty);
    expect(model.hasData, isTrue);
    expect(model.rasterTileset, same(rasterTileset));
    expect(rasterTileset.disposed, isFalse);
  });

  test(
      'cancellation while the raster tileset loads leaves no unhandled error '
      'and disposes the raster tileset', () async {
    final errors = await unhandledErrors(() async {
      model.startLoading();
      await untilRequested();
      tileProvider.pending!.completeError(CancellationException());
      await Future<void>.delayed(Duration.zero);
      rasterTileProvider.pending!.complete(rasterTileset);
      await Future<void>.delayed(Duration.zero);
    });
    expect(errors, isEmpty);
    expect(model.hasData, isFalse);
    expect(rasterTileset.disposed, isTrue);
  });

  test('a failed raster tileset load leaves no unhandled error', () async {
    final errors = await unhandledErrors(() async {
      model.startLoading();
      await untilRequested();
      rasterTileProvider.pending!
          .completeError(const SocketException('offline'));
      await Future<void>.delayed(Duration.zero);
      tileProvider.pending!.completeError(CancellationException());
      await Future<void>.delayed(Duration.zero);
    });
    expect(errors, isEmpty);
    expect(model.hasData, isFalse);
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

class _RecordingRasterTileset extends RasterTileset {
  var disposed = false;

  _RecordingRasterTileset() : super(tiles: const {});

  @override
  void dispose() {
    disposed = true;
    super.dispose();
  }
}
