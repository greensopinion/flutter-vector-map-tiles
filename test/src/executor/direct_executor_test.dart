import 'package:test/test.dart';
import 'package:vector_map_tiles/src/executor/direct_executor.dart';

void main() {
  var executor = DirectExecutor();

  setUp(() {
    if (executor.disposed) {
      executor = DirectExecutor();
    }
  });

  tearDown(() {
    executor.dispose();
  });

  test('runs a task', () async {
    final result = await executor.submit(_task, 3);
    expect(result, equals(4));
  });

  test('runs a submit all task', () async {
    final result = executor.submitAll(_task, 3);
    expect(result.length, 1);
    expect(await result[0], equals(4));
  });
}

dynamic _task(dynamic value) {
  return value + 1;
}
