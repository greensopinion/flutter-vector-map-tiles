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
}

dynamic _task(dynamic value) {
  return value + 1;
}
