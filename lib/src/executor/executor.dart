import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:vector_map_tiles/src/executor/direct_executor.dart';
import 'package:vector_map_tiles/src/executor/pool_executor.dart';

abstract class Executor {
  Future<R> submit<Q, R>(ComputeCallback<Q, R> computeFunction, Q value);

  /// submits the given function and value to all isolates in the executor
  List<Future<R>> submitAll<Q, R>(
      ComputeCallback<Q, R> computeFunction, Q value);

  void dispose();
  bool get disposed;
}

Executor newExecutor() =>
    kDebugMode ? DirectExecutor() : PoolExecutor(concurrency: 3);
