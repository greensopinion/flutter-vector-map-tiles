import 'dart:async';

import 'executor.dart';

class DirectExecutor extends Executor {
  var _disposed = false;
  @override
  void dispose() {
    _disposed = true;
  }

  @override
  bool get disposed => _disposed;

  @override
  Future<R> submit<Q, R>(Job<Q, R> job) {
    if (_disposed) {
      throw 'disposed';
    }
    final completer = Completer<R>();
    scheduleMicrotask(() async {
      try {
        if (job.isCancelled) {
          throw CancellationException();
        }
        completer.complete(await job.computeFunction(job.value));
      } catch (error, stack) {
        completer.completeError(error, stack);
      }
    });
    return completer.future;
  }

  @override
  List<Future<R>> submitAll<Q, R>(Job<Q, R> job) => [submit(job)];
}
