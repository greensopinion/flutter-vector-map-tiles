import 'dart:async';

import 'package:executor_lib/executor_lib.dart';
import 'package:test/test.dart';
import 'package:vector_map_tiles/src/cache/memory_cache.dart';
import 'package:vector_map_tiles/src/cache/storage_cache.dart';
import 'package:vector_map_tiles/src/cache/vector_tile_loading_cache.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

void main() {
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

  test(
      'disposing the executor before the theme is set up leaves no '
      'unhandled error', () async {
    final errors = await unhandledErrors(() async {
      final executor = QueueExecutor();
      VectorTileLoadingCache(
          _FakeStorageCache(),
          _FakeMemoryCache(),
          _FakeMemoryTileDataCache(),
          TileProviders({'a': _FakeVectorTileProvider()}),
          executor,
          ThemeReader().read({'id': 'a-theme', 'layers': <dynamic>[]}));
      executor.dispose();
    });
    expect(errors, isEmpty);
  });
}

class _FakeStorageCache implements StorageCache {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeMemoryCache implements MemoryCache {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeMemoryTileDataCache implements MemoryTileDataCache {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeVectorTileProvider implements VectorTileProvider {
  @override
  int get maximumZoom => 14;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
