import 'dart:async';

import 'dart:isolate';
import 'package:async/async.dart';
import 'package:flutter/foundation.dart';

import 'executor.dart';

class IsolateExecutor extends Executor {
  final _ready = Completer<bool>();
  bool _isReady = false;
  SendPort? _sendPort;
  StreamQueue<dynamic>? _stream;
  var _disposed = false;
  final Map<String, _Job> _jobByKey = {};
  var _keySeed = 0;
  var _outstanding = 0;
  var _submitted = 0;
  var _queue = <_Job>[];

  IsolateExecutor() {
    _start();
  }

  void dispose() {
    _disposed = true;
    _sendPort?.send(null);
    _sendPort = null;
    _stream = null;
  }

  @override
  bool get disposed => _disposed;

  int get outstanding => _outstanding;

  @override
  List<Future<R>> submitAll<Q, R>(Job<Q, R> job) => [submit(job)];

  Future<R> submit<Q, R>(Job<Q, R> job) async {
    if (_disposed) {
      throw 'disposed';
    }
    if (!_isReady) {
      await _ready.future;
    }
    final key = _newKey();
    final internalJob = _Job<Q, R>(key, job);
    _jobByKey[key] = internalJob;
    ++_outstanding;
    try {
      _queueJob(internalJob);
      return await internalJob.completer.future;
    } finally {
      --_outstanding;
    }
  }

  void _queueJob(_Job work) {
    _queue.add(work); //LIFO
    _submitOne();
  }

  void _submitOne() {
    _queue.removeWhere((job) {
      if (job.job.isCancelled) {
        job.completer.completeError(CancellationException());
        return true;
      }
      return false;
    });
    if (_submitted == 0 && _queue.isNotEmpty) {
      final job = _queue.removeLast(); //LIFO
      ++_submitted;
      _submit(job);
    }
  }

  void _submit(_Job work) {
    final sendPort = _sendPort!;
    sendPort.send(work.input);
  }

  void _start() async {
    final receivePort = ReceivePort();
    await Isolate.spawn(_executorService, receivePort.sendPort);
    _stream = StreamQueue<dynamic>(receivePort);
    final sendPort = (await _stream!.next) as SendPort;
    _sendPort = sendPort;
    _isReady = true;
    _ready.complete(true);
    if (_disposed) {
      sendPort.send(null);
      dispose();
    }
    _receiveWork();
  }

  void _receiveWork() async {
    if (!_isReady) {
      await _ready.future;
    }
    final stream = _stream;
    if (stream == null || _disposed) {
      return;
    }
    final result = await stream.next;
    if (result is _Error) {
      if (result.key != null) {
        --_submitted;
        final work = _jobByKey.remove(result.key);
        work?.completer.completeError(result.error, result.stack);
      } else {
        print(result.error);
        print(result.stack);
      }
    } else if (result is _JobOutput) {
      --_submitted;
      final work = _jobByKey.remove(result.key);
      work?.completer.complete(result.message);
    } else {
      print('unexpected message: $result');
    }
    _submitOne();
    _receiveWork();
  }

  String _newKey() {
    final thisKey = _keySeed++;
    return '$thisKey';
  }
}

class _Job<Q, R> {
  final String key;
  final Job<Q, R> job;
  final completer = Completer();

  _Job(this.key, this.job);

  _JobInput<Q, R> get input => _JobInput(key, job.computeFunction, job.value);
}

class _JobInput<Q, R> {
  final String key;
  final ComputeCallback<Q, R> computeFunction;
  final Q message;

  _JobInput(this.key, this.computeFunction, this.message);

  Future<R> apply() async => await computeFunction(message);
}

class _JobOutput {
  final String key;
  final message;

  _JobOutput(this.key, this.message);
}

class _Error {
  final String? key;
  final error;
  final stack;

  _Error(this.key, this.error, this.stack);
}

Future<void> _executorService(SendPort port) async {
  final commandPort = ReceivePort();
  final commandStream = StreamQueue<dynamic>(commandPort);

  port.send(commandPort.sendPort);

  while (true) {
    final command = await commandStream.next;
    if (command is _JobInput) {
      command.apply().then((result) {
        port.send(_JobOutput(command.key, result));
      }).onError((error, stack) {
        port.send(_Error(command.key, error, stack));
      });
    } else if (command != null) {
      port.send(_Error(null, 'Unexpected message: $command', null));
    } else {
      break;
    }
  }
  commandStream.cancel(immediate: true);
  Isolate.exit();
}
