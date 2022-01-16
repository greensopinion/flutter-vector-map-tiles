import 'dart:async';

import 'package:vector_map_tiles/src/executor/executor.dart';

class QueueExecutor extends Executor {
  bool _disposed = false;
  final _queue = <_Job>[];
  var _scheduled = false;

  @override
  void dispose() {
    _disposed = true;
  }

  @override
  bool get disposed => _disposed;

  @override
  Future<R> submit<Q, R>(Job<Q, R> job) {
    final internalJob = _Job(job);
    _queue.add(internalJob); //LIFO
    _schedule();
    return internalJob.completer.future;
  }

  @override
  List<Future<R>> submitAll<Q, R>(Job<Q, R> job) => [submit(job)];

  void _schedule() {
    _completeCancelled();
    if (!_scheduled && _queue.isNotEmpty) {
      _scheduled = true;
      scheduleMicrotask(_runOneAndReschedule);
    }
  }

  void _runOneAndReschedule() async {
    _scheduled = false;
    if (_queue.isNotEmpty) {
      final job = _queue.removeLast(); //LIFO
      try {
        if (_disposed) {
          throw 'disposed';
        }
        if (job.request.isCancelled) {
          throw CancellationException();
        }
        final result = await job.apply();
        job.completer.complete(result);
        _completeCancelled();
        _completeDuplicates(job, result);
      } catch (error, stack) {
        job.completer.completeError(error, stack);
      }
    }
    _schedule();
  }

  void _completeDuplicates(_Job job, result) {
    final deduplicationKey = job.request.deduplicationKey;
    if (deduplicationKey != null) {
      _queue.removeWhere((queued) {
        if (queued.request.deduplicationKey == deduplicationKey) {
          queued.completer.complete(result);
          return true;
        }
        return false;
      });
    }
  }

  void _completeCancelled() {}
}

class _Job<Q, R> {
  final Job<Q, R> request;
  final completer = Completer<R>();

  _Job(this.request);

  Future<R> apply() async => await request.computeFunction(request.value);
}
