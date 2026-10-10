import 'dart:async';

import 'package:executor_lib/executor_lib.dart';
import 'package:test/test.dart';
import 'package:vector_map_tiles/src/cache/caches.dart';
import 'package:vector_map_tiles/src/cache/vector_tile_loading_cache.dart';
import 'package:vector_map_tiles/src/stream/caches_tile_provider.dart';
import 'package:vector_map_tiles/src/stream/tile_processor.dart';
import 'package:vector_map_tiles/src/stream/tile_supplier.dart';
import 'package:vector_map_tiles/src/stream/tileset_executor_preprocessor.dart';
import 'package:vector_map_tiles/src/stream/tileset_ui_preprocessor.dart';
import 'package:vector_map_tiles/src/tile_identity.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

void main() {
  late _FakeVectorTileCache vectorTileCache;
  late _FakeTileProcessor tileProcessor;
  late CachesTileProvider provider;
  var cancelled = false;

  setUp(() {
    cancelled = false;
    vectorTileCache = _FakeVectorTileCache();
    tileProcessor = _FakeTileProcessor();
    provider = CachesTileProvider(_FakeCaches(vectorTileCache), tileProcessor,
        _FakeExecutorPreprocessor(), _FakeUiPreprocessor());
  });

  TileRequest request(Set<String> sources) => TileRequest(
      tileId: TileIdentity(10, 1, 2),
      tileSources: sources,
      zoom: 10,
      zoomDetail: 10,
      cancelled: () => cancelled);

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

  test('cancellation while retrieving leaves no unhandled error', () async {
    final errors = await unhandledErrors(() async {
      cancelled = true;
      await expectLater(provider.provide(request({'a', 'b'})),
          throwsA(isA<CancellationException>()));
      // the executor fails the abandoned jobs once it sees the cancellation
      vectorTileCache.failAll(CancellationException());
    });
    expect(vectorTileCache.pending, hasLength(2));
    expect(errors, isEmpty);
  });

  test('cancellation while processing leaves no unhandled error', () async {
    final errors = await unhandledErrors(() async {
      tileProcessor.onProcess = () => cancelled = true;
      final response = provider.provide(request({'a', 'b'}));
      vectorTileCache.completeAll();
      await expectLater(response, throwsA(isA<CancellationException>()));
      tileProcessor.failAll(CancellationException());
    });
    expect(tileProcessor.pending, hasLength(2));
    expect(errors, isEmpty);
  });
}

class _FakeCaches implements Caches {
  @override
  final VectorTileLoadingCache vectorTileCache;

  _FakeCaches(this.vectorTileCache);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeVectorTileCache implements VectorTileLoadingCache {
  final pending = <Completer<TileData?>>[];

  @override
  Future<TileData?> retrieve(String source, TileIdentity tile,
      {required CancellationCallback cancelled, required bool cachedOnly}) {
    final completer = Completer<TileData?>();
    pending.add(completer);
    return completer.future;
  }

  void completeAll() {
    for (final completer in pending) {
      completer.complete(TileData(layers: []));
    }
  }

  void failAll(Object error) {
    for (final completer in pending) {
      completer.completeError(error);
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeTileProcessor implements TileProcessor {
  final pending = <Completer<Tile>>[];
  void Function()? onProcess;

  @override
  Future<Tile> process(TileRequest request, String source, TileData tileData,
      CancellationCallback cancelled) {
    onProcess?.call();
    final completer = Completer<Tile>();
    pending.add(completer);
    return completer.future;
  }

  void failAll(Object error) {
    for (final completer in pending) {
      completer.completeError(error);
    }
  }
}

class _FakeExecutorPreprocessor implements TilesetExecutorPreprocessor {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeUiPreprocessor implements TilesetUiPreprocessor {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
