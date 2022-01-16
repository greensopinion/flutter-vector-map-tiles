import 'package:flutter/foundation.dart';

import 'executor.dart';
import 'isolate_executor.dart';

class PoolExecutor extends Executor {
  int _index = 0;
  late final List<IsolateExecutor> _delegates;

  PoolExecutor({required int concurrency}) {
    assert(concurrency > 0);
    _delegates = List.generate(concurrency, (index) => IsolateExecutor());
  }

  @override
  void dispose() {
    _delegates.forEach((delegate) {
      delegate.dispose();
    });
  }

  @override
  bool get disposed => _delegates[0].disposed;

  @override
  List<Future<R>> submitAll<Q, R>(Job<Q, R> job) =>
      _delegates.map((delegate) => delegate.submit(job)).toList();

  @override
  Future<R> submit<Q, R>(Job<Q, R> job) => _nextDelegate().submit(job);

  Executor _nextDelegate() {
    for (int attempt = 0; attempt < _delegates.length; ++attempt) {
      final delegate = _delegates[_nextIndex()];
      if (delegate.outstanding == 0) {
        return delegate;
      }
    }
    return _delegates[_nextIndex()];
  }

  int _nextIndex() {
    ++_index;
    if (_index == _delegates.length) {
      _index = 0;
    }
    return _index;
  }
}
