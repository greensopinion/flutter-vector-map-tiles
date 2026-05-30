import 'package:executor_lib/executor_lib.dart';
import 'package:flutter/foundation.dart';

import 'executors.dart';

// Private module-level state
Executor? _sharedExecutor;
int _refCount = 0;

/// Acquires a reference to the shared executor.
/// Creates a new executor via [newConcurrentExecutor] if none exists.
/// Increments the reference count.
Executor acquireSharedExecutor({required int concurrency}) {
  _sharedExecutor ??= newConcurrentExecutor(concurrency: concurrency);
  _refCount++;
  return _sharedExecutor!;
}

/// Releases a reference to the shared executor.
/// Decrements the reference count.
/// Disposes the executor when the count reaches zero.
void releaseSharedExecutor() {
  assert(_refCount > 0, 'releaseSharedExecutor called with zero ref count');
  if (_refCount <= 0) return; // no-op in release mode
  _refCount--;
  if (_refCount == 0) {
    _sharedExecutor?.dispose();
    _sharedExecutor = null;
  }
}

@visibleForTesting
int get sharedExecutorRefCountForTesting => _refCount;

@visibleForTesting
Executor? get sharedExecutorForTesting => _sharedExecutor;

@visibleForTesting
void resetSharedExecutorForTesting() {
  _sharedExecutor?.dispose();
  _sharedExecutor = null;
  _refCount = 0;
}
