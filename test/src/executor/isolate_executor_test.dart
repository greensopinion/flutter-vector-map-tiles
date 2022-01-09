import 'package:test/test.dart';
import 'package:vector_map_tiles/src/executor/isolate_executor.dart';

void main() {
  var executor = IsolateExecutor();

  setUp(() {
    if (executor.disposed) {
      executor = IsolateExecutor();
    }
  });

  tearDown(() {
    executor.dispose();
  });

  group("executes tasks:", () {
    test('a single task', () async {
      final result = await executor.submit(_task, 1);
      expect(result, equals(2));
    });
    test('multiple tasks', () async {
      final futures =
          [1, 2, 3, 4].map((e) => executor.submit(_task, e)).toList();
      final results = [];
      for (final future in futures) {
        results.add(await future);
      }
      expect(results, equals([2, 3, 4, 5]));
    });
    test('propagates an exception', () async {
      final message = 'intentional failure';
      try {
        await executor.submit(_throwingTask, message);
        throw 'expected a failure';
      } catch (error) {
        expect(error, equals(message));
      }
    });
  });

  group('submitAll tasks:', () {
    test('runs a task', () async {
      final result = executor.submitAll(_task, 3);
      expect(result.length, 1);
      expect(await result[0], equals(4));
    });
  });

  group('shuts down', () {
    test('can be disposed', () {
      executor.dispose();
      expect(executor.disposed, equals(true));
    });

    test('can be disposed twice', () {
      executor.dispose();
      expect(executor.disposed, equals(true));
      executor.dispose();
      expect(executor.disposed, equals(true));
    });

    test('rejects tasks when disposed', () async {
      executor.dispose();
      try {
        await executor.submit((message) => _task, 'a-message');
        throw 'expected an error';
      } catch (error) {
        expect(error, 'disposed');
      }
    });
  });
}

dynamic _task(dynamic value) {
  return value + 1;
}

dynamic _throwingTask(dynamic value) {
  throw value;
}
