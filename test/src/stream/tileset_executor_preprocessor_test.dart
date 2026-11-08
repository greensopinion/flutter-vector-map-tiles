import 'dart:async';

import 'package:executor_lib/executor_lib.dart';
import 'package:test/test.dart';
import 'package:vector_map_tiles/src/stream/tileset_executor_preprocessor.dart';
import 'package:vector_map_tiles/src/tile_identity.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

void main() {
  final theme = ThemeReader().read({'id': 'a-theme', 'layers': <dynamic>[]});

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

  test('preprocesses a tileset once set up', () async {
    final executor = QueueExecutor();
    final preprocessor =
        TilesetExecutorPreprocessor(TilesetPreprocessor(theme), executor);
    final tileset = await preprocessor.preprocess(
        TileIdentity(1, 0, 0), Tileset({}), null, 1, () => false);
    expect(tileset.preprocessed, isTrue);
    executor.dispose();
  });

  test(
      'disposing the executor before the preprocessor is set up leaves no '
      'unhandled error', () async {
    final errors = await unhandledErrors(() async {
      final executor = QueueExecutor();
      TilesetExecutorPreprocessor(TilesetPreprocessor(theme), executor);
      executor.dispose();
    });
    expect(errors, isEmpty);
  });
}
