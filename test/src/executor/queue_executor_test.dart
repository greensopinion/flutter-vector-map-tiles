import 'package:test/test.dart';
import 'package:vector_map_tiles/src/executor/executor.dart';
import 'package:vector_map_tiles/src/executor/queue_executor.dart';

void main() {
  var executor = QueueExecutor();

  setUp(() {
    executor = QueueExecutor();
  });

  tearDown(() {
    _delayValues = [];
  });

  group("executes tasks:", () {
    test('a single task', () async {
      final result = await executor
          .submit(Job(_testJobName, _task, 1, deduplicationKey: null));
      expect(result, equals(2));
    });
    test('multiple tasks', () async {
      final futures = [1, 2, 3, 4]
          .map((e) => executor
              .submit(Job(_testJobName, _task, e, deduplicationKey: null)))
          .toList();
      final results = [];
      for (final future in futures) {
        results.add(await future);
      }
      expect(results, equals([2, 3, 4, 5]));
    });
    test('propagates an exception', () async {
      const message = 'intentional failure';
      try {
        await executor.submit(
            Job(_testJobName, _throwingTask, message, deduplicationKey: null));
        throw 'expected a failure';
      } catch (error) {
        expect(error, equals(message));
      }
    });

    test('executes in LIFO order', () async {
      final longRunningTask = executor
          .submit(Job(_testJobName, _delayTask, 10, deduplicationKey: null));
      final firstShortTask = executor
          .submit(Job(_testJobName, _delayTask, 20, deduplicationKey: null));
      final secondShortTask = executor
          .submit(Job(_testJobName, _delayTask, 30, deduplicationKey: null));
      final longResult = await longRunningTask;
      await firstShortTask;
      await secondShortTask;
      expect(longResult, [30, 20, 10]);
    });

    test('rejects tasks when task is cancelled', () async {
      try {
        await executor.submit(Job(_testJobName, (message) => _task, 'a-message',
            cancelled: () => true, deduplicationKey: null));
        throw 'expected an error';
      } on CancellationException {
        // ignore
      }
    });
  });

  group('submitAll tasks:', () {
    test('runs a task', () async {
      final result = executor
          .submitAll(Job(_testJobName, _task, 3, deduplicationKey: null));
      expect(result.length, 1);
      expect(await result[0], equals(4));
    });
  });

  group('deduplication:', () {
    test('deduplicates tasks', () async {
      const aKey = 'a-key';
      final longRunningTask = executor
          .submit(Job(_testJobName, _delayTask, 1000, deduplicationKey: aKey));
      final firstShortTask =
          executor.submit(Job(_testJobName, _task, 2, deduplicationKey: aKey));
      final secondShortTask =
          executor.submit(Job(_testJobName, _task, 3, deduplicationKey: aKey));
      final longResult = await longRunningTask;
      final firstShortResult = await firstShortTask;
      final secondShortResult = await secondShortTask;

      expect(longResult, 4);
      expect(firstShortResult, 4);
      expect(secondShortResult, 4);
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
        await executor.submit(Job(_testJobName, (message) => _task, 'a-message',
            deduplicationKey: null));
        throw 'expected an error';
      } on CancellationException catch (_) {
        // expetced, ignore
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

var _delayValues = [];

dynamic _delayTask(dynamic value) async {
  await Future.delayed(Duration(milliseconds: value));
  _delayValues.add(value);
  return _delayValues;
}

const _testJobName = 'test';
