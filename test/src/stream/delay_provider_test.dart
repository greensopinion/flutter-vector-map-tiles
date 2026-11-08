import 'dart:async';

import 'package:executor_lib/executor_lib.dart';
import 'package:test/test.dart';
import 'package:vector_map_tiles/src/stream/delay_provider.dart';
import 'package:vector_map_tiles/src/stream/tile_supplier.dart';
import 'package:vector_map_tiles/src/tile_identity.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

void main() {
  final tile = TileIdentity(10, 1, 2);
  late _FakeTileProvider delegate;
  late DelayProvider provider;

  setUp(() {
    delegate = _FakeTileProvider();
    provider = DelayProvider(delegate, const Duration(milliseconds: 20));
  });

  TileRequest request() => TileRequest(
      tileId: tile,
      tileSources: {'a'},
      zoom: 10,
      zoomDetail: 10,
      cancelled: () => false);

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

  test('returns the tile after the delay', () async {
    final errors = await unhandledErrors(() async {
      final response = provider.provide(request());
      final tileResponse = TileResponse(identity: tile, tileset: Tileset({}));
      delegate.pending!.complete(tileResponse);
      expect(await response, same(tileResponse));
    });
    expect(errors, isEmpty);
  });

  test('cancellation during the delay leaves no unhandled error', () async {
    final errors = await unhandledErrors(() async {
      final response = provider.provide(request());
      delegate.pending!.completeError(CancellationException());
      await expectLater(response, throwsA(isA<CancellationException>()));
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
