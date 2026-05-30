import 'dart:math';

import 'package:test/test.dart';
import 'package:vector_map_tiles/src/executors/shared_executor.dart';

void main() {
  setUp(() {
    resetSharedExecutorForTesting();
  });

  tearDown(() {
    resetSharedExecutorForTesting();
  });

  group('acquireSharedExecutor', () {
    test('first call creates an executor and sets ref count to 1', () {
      final executor = acquireSharedExecutor(concurrency: 4);
      expect(executor, isNotNull);
      expect(sharedExecutorRefCountForTesting, equals(1));
      expect(sharedExecutorForTesting, same(executor));
    });

    test('subsequent acquires return the same instance and increment ref count',
        () {
      final first = acquireSharedExecutor(concurrency: 4);
      final second = acquireSharedExecutor(concurrency: 4);
      final third = acquireSharedExecutor(concurrency: 2);

      expect(second, same(first));
      expect(third, same(first));
      expect(sharedExecutorRefCountForTesting, equals(3));
    });
  });

  group('releaseSharedExecutor', () {
    test('decrements ref count', () {
      acquireSharedExecutor(concurrency: 4);
      acquireSharedExecutor(concurrency: 4);
      expect(sharedExecutorRefCountForTesting, equals(2));

      releaseSharedExecutor();
      expect(sharedExecutorRefCountForTesting, equals(1));
    });

    test('releasing to zero disposes the executor and nulls the reference', () {
      final executor = acquireSharedExecutor(concurrency: 4);
      releaseSharedExecutor();

      expect(sharedExecutorRefCountForTesting, equals(0));
      expect(sharedExecutorForTesting, isNull);
      expect(executor.disposed, isTrue);
    });

    test('with zero ref count triggers assertion in debug mode', () {
      expect(
        () => releaseSharedExecutor(),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('re-creation after full disposal', () {
    test('returns a new, distinct instance', () {
      final first = acquireSharedExecutor(concurrency: 4);
      releaseSharedExecutor();

      expect(sharedExecutorForTesting, isNull);

      final second = acquireSharedExecutor(concurrency: 4);
      expect(second, isNot(same(first)));
      expect(second.disposed, isFalse);
      expect(sharedExecutorRefCountForTesting, equals(1));
    });
  });

  group('Property-based tests', () {
    test(
      'Feature: shared-executor-instance, Property 2: Reference count correctness',
      () {
        // Validates: Requirements 2.1, 2.2, 3.3, 6.3
        final random = Random();

        for (var iteration = 0; iteration < 100; iteration++) {
          resetSharedExecutorForTesting();
          var expectedRefCount = 0;
          final sequenceLength = random.nextInt(50) + 1;

          for (var i = 0; i < sequenceLength; i++) {
            // Decide whether to acquire or release
            final canRelease = expectedRefCount > 0;
            final shouldAcquire = !canRelease || random.nextBool();

            if (shouldAcquire) {
              acquireSharedExecutor(concurrency: 4);
              expectedRefCount++;
            } else {
              releaseSharedExecutor();
              expectedRefCount--;
            }

            expect(
              sharedExecutorRefCountForTesting,
              equals(expectedRefCount),
              reason:
                  'Iteration $iteration, step $i: ref count mismatch',
            );
          }
        }
      },
    );

    test(
      'Feature: shared-executor-instance, Property 1: Shared identity',
      () {
        // Validates: Requirements 1.1, 1.4, 5.3
        final random = Random();

        for (var iteration = 0; iteration < 100; iteration++) {
          resetSharedExecutorForTesting();
          final acquireCount = random.nextInt(50) + 1;
          final executors = <dynamic>[];

          for (var i = 0; i < acquireCount; i++) {
            executors.add(acquireSharedExecutor(concurrency: 4));
          }

          // All returned references should be identical
          final first = executors.first;
          for (var i = 1; i < executors.length; i++) {
            expect(
              executors[i],
              same(first),
              reason:
                  'Iteration $iteration: acquire $i returned different instance',
            );
          }
        }
      },
    );

    test(
      'Feature: shared-executor-instance, Property 3: Disposal iff zero references',
      () {
        // Validates: Requirements 2.3, 2.4, 5.1, 5.2
        final random = Random();

        for (var iteration = 0; iteration < 100; iteration++) {
          resetSharedExecutorForTesting();
          var refCount = 0;
          final sequenceLength = random.nextInt(50) + 1;

          for (var i = 0; i < sequenceLength; i++) {
            final canRelease = refCount > 0;
            final shouldAcquire = !canRelease || random.nextBool();

            if (shouldAcquire) {
              acquireSharedExecutor(concurrency: 4);
              refCount++;
            } else {
              releaseSharedExecutor();
              refCount--;
            }

            if (refCount == 0) {
              // Executor should be disposed and null
              expect(
                sharedExecutorForTesting,
                isNull,
                reason:
                    'Iteration $iteration, step $i: executor should be null at ref count 0',
              );
            } else {
              // Executor should exist and not be disposed
              expect(
                sharedExecutorForTesting,
                isNotNull,
                reason:
                    'Iteration $iteration, step $i: executor should exist at ref count $refCount',
              );
              expect(
                sharedExecutorForTesting!.disposed,
                isFalse,
                reason:
                    'Iteration $iteration, step $i: executor should not be disposed at ref count $refCount',
              );
            }
          }
        }
      },
    );

    test(
      'Feature: shared-executor-instance, Property 4: Re-creation after full disposal',
      () {
        // Validates: Requirements 3.1, 3.2
        final random = Random();

        for (var iteration = 0; iteration < 100; iteration++) {
          resetSharedExecutorForTesting();
          final acquireCount = random.nextInt(20) + 1;

          // Acquire N times
          for (var i = 0; i < acquireCount; i++) {
            acquireSharedExecutor(concurrency: 4);
          }
          final firstExecutor = sharedExecutorForTesting;

          // Release N times to cause disposal
          for (var i = 0; i < acquireCount; i++) {
            releaseSharedExecutor();
          }
          expect(sharedExecutorForTesting, isNull,
              reason: 'Iteration $iteration: executor should be null after full release');
          expect(firstExecutor!.disposed, isTrue,
              reason: 'Iteration $iteration: first executor should be disposed');

          // Acquire again — should create a new distinct instance
          final newExecutor = acquireSharedExecutor(concurrency: 4);
          expect(
            newExecutor,
            isNot(same(firstExecutor)),
            reason:
                'Iteration $iteration: new executor should be distinct from disposed one',
          );
          expect(newExecutor.disposed, isFalse,
              reason: 'Iteration $iteration: new executor should not be disposed');
          expect(sharedExecutorRefCountForTesting, equals(1),
              reason: 'Iteration $iteration: ref count should be 1 after re-creation');
        }
      },
    );
  });
}
