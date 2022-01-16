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
      throw 'disposed';
    }
    if (job.isCancelled) {
      throw CancellationException();
    }
    return await job.computeFunction(job.value);
  }

  @override
  List<Future<R>> submitAll<Q, R>(Job<Q, R> job) => [submit(job)];
}
