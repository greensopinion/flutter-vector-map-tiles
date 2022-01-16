import 'package:test/test.dart';
import 'package:vector_map_tiles/src/executor/direct_executor.dart';
import 'package:vector_map_tiles/src/executor/executor.dart';

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
    final result = await executor.submit(Job(_testJobName, _task, 3));
    expect(result, equals(4));
  });

  test('runs a submit all task', () async {
    final result = executor.submitAll(Job(_testJobName, _task, 3));
    expect(result.length, 1);
    expect(await result[0], equals(4));
  });
}

dynamic _task(dynamic value) {
  return value + 1;
}

const _testJobName = 'test';
