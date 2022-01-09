import 'package:flutter/foundation.dart';

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
  Future<R> submit<Q, R>(ComputeCallback<Q, R> computeFunction, Q value) async {
    if (_disposed) {
      throw 'disposed';
    }
    return await computeFunction(value);
  }

  @override
  List<Future<R>> submitAll<Q, R>(
          ComputeCallback<Q, R> computeFunction, Q value) =>
      [submit(computeFunction, value)];
}
