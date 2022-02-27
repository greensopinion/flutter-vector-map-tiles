import 'dart:async';

import 'package:vector_map_tiles/src/executor/executor.dart';

class QueueExecutor extends Executor {
  bool _disposed = false;
  final _queue = <_Job>[];
  var _scheduled = false;

  @override
  void dispose() {
    if (!_disposed) {
      _disposed = true;
      _completeCancelled(cancelAll: true);
    }
  }

  @override
  bool get disposed => _disposed;

  @override
  Future<R> submit<Q, R>(Job<Q, R> job) async {
    if (_disposed) {
      throw CancellationException();
    }
    final internalJob = _Job(job);
    _queue.add(internalJob); //LIFO
    _schedule();
    return internalJob.completer.future;
  }

  @override
  List<Future<R>> submitAll<Q, R>(Job<Q, R> job) => [submit(job)];

  void _schedule() {
    if (!_disposed && !_scheduled && _queue.isNotEmpty) {
      _scheduled = true;
      scheduleMicrotask(_runOneAndReschedule);
    }
  }

  void _runOneAndReschedule() async {
    _scheduled = false;
    _completeCancelled(cancelAll: _disposed);
    if (_queue.isNotEmpty && !_disposed) {
      final job = _queue.removeLast(); //LIFO
      try {
        if (_disposed || job.request.isCancelled) {
          throw CancellationException();
        }
        final result = await job.apply();
        job.completer.complete(result);
        _completeCancelled(cancelAll: false);
        _completeDuplicates(job, result);
      } catch (error, stack) {
        if (!job.completer.isCompleted) {
          job.completer.completeError(error, stack);
        }
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

  void _completeCancelled({required bool cancelAll}) {
    _queue.removeWhere((queued) {
      if (cancelAll || queued.request.isCancelled) {
        if (!queued.completer.isCompleted) {
          queued.completer.completeError(CancellationException());
        }
        return true;
      }
      return false;
    });
  }
}

class _Job<Q, R> {
  final Job<Q, R> request;
  final completer = Completer<R>();

  _Job(this.request);

  Future<R> apply() async => await request.computeFunction(request.value);
}
