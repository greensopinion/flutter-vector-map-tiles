import 'dart:async';

import 'package:flutter/foundation.dart';

import 'direct_executor.dart';
import 'pool_executor.dart';

class Job<Q, R> {
  final String name;
  final ComputeCallback<Q, R> computeFunction;
  final Q value;

  Job(this.name, this.computeFunction, this.value);
}

abstract class Executor {
  Future<R> submit<Q, R>(Job<Q, R> job);

  /// submits the given function and value to all isolates in the executor
  List<Future<R>> submitAll<Q, R>(Job<Q, R> job);

  void dispose();
  bool get disposed;
}

Executor newExecutor() =>
    kDebugMode ? DirectExecutor() : PoolExecutor(concurrency: 3);
