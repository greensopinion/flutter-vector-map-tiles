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
  Future<R> submit<Q, R>(Job<Q, R> job) async {
    if (_disposed) {
      throw CancellationException();
    }
    final completer = Completer<R>();
    scheduleMicrotask(() async {
      try {
        if (_disposed || job.isCancelled) {
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
