import 'dart:async';

import 'package:flutter/foundation.dart';

abstract class Executor {
  Future<R> submit<Q, R>(ComputeCallback<Q, R> computeFunction, Q value);
  void dispose();
  bool get disposed;
}
