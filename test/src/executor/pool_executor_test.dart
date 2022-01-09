import 'package:test/test.dart';
import 'package:vector_map_tiles/src/executor/pool_executor.dart';

void main() {
  var executor = PoolExecutor(concurrency: 3);

  setUp(() {
    if (executor.disposed) {
      executor = PoolExecutor(concurrency: 3);
    }
  });

  tearDown(() {
    executor.dispose();
  });

  test('runs multiple tasks', () async {
    final futures =
        [1, 2, 3, 4, 5].map((e) => executor.submit(_task, e)).toList();
    final results = [];
    for (final future in futures) {
      results.add(await future);
    }
    expect(results, equals([2, 3, 4, 5, 6]));
  });
}

dynamic _task(dynamic value) {
  return value + 1;
}
