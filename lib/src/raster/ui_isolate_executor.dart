import 'dart:async';
import 'dart:isolate';

import 'package:async/async.dart';
import 'package:dart_ui_isolate/dart_ui_isolate.dart';
import 'package:executor_lib/executor_lib.dart';

class UiIsolateExecutor extends ExecutorDelegate {
  bool _disposed = false;

  final void Function(dynamic) entrypoint;
  final Map? entrypointParameters;
  ReceivePort? _receivePort;
  SendPort? _sendPort;
  DartUiIsolate? _isolate;
  final _initializationComplete = Completer<bool>();
  int _outstanding = 0;

  UiIsolateExecutor(
      {required this.entrypoint, required this.entrypointParameters});

  @override
  void dispose() {
    if (!_disposed) {
      _disposed = true;
      try {
        _sendPort?.send(null);
        _receivePort?.close();
      } catch (e, stack) {
        // ignore: avoid_print
        print(e);
        // ignore: avoid_print
        print(stack);
      } finally {
        _isolate?.kill();
      }
    }
  }

  @override
  bool get disposed => _disposed;

  @override
  Future<R> submit<Q, R>(Job<Q, R> job) async {
    ReceivePort? receivePort = _receivePort;
    if (receivePort == null) {
      receivePort = ReceivePort();
      _receivePort = receivePort;
      try {
        _isolate = await DartUiIsolate.spawn(entrypoint,
            {_port: receivePort.sendPort, _args: entrypointParameters ?? {}});
        _sendPort = await receivePort.first as SendPort;
        _initializationComplete.complete(true);
      } catch (e, stack) {
        _initializationComplete.completeError(e, stack);
      }
    }
    await _initializationComplete.future;
    if (job.isCancelled) {
      throw CancellationException();
    }
    final sendPort = _sendPort!;
    ++_outstanding;
    final receive = ReceivePort();
    try {
      final args = {_port: receive.sendPort, _args: job.value};
      sendPort.send(args);
      final response = await receive.first;
      if (response is Map && response[_error] != null) {
        throw Exception(response[_error]);
      }
      return response;
    } finally {
      --_outstanding;
      receive.close();
    }
  }

  @override
  List<Future<R>> submitAll<Q, R>(Job<Q, R> job) => [submit(job)];

  @override
  bool hasJobWithDeduplicationKey(Job job) => false;

  @override
  int get outstanding => _outstanding;
}

Future executeIsolateMessages(
    {required dynamic initialMessage,
    required Future Function(dynamic) executor}) async {
  final sendPort = ((initialMessage) as Map)[_port] as SendPort;
  final commandPort = ReceivePort();
  final commandStream = StreamQueue<dynamic>(commandPort);
  try {
    sendPort.send(commandPort.sendPort);

    while (true) {
      final command = await commandStream.next;
      if (command is Map) {
        final args = _decodeUiExecutorArguments(request: command);
        executor(args).then((result) {
          _sendUiExecutorResponse(request: command, response: result);
        }).onError((error, stack) {
          // ignore: avoid_print
          print(error);
          // ignore: avoid_print
          print(stack);
          final response = {_error: error.toString(), _stack: stack.toString()};
          _sendUiExecutorResponse(request: command, response: response);
        });
      } else {
        break;
      }
    }
  } finally {
    commandStream.cancel(immediate: true);
    commandPort.close();
    DartUiIsolate.current.kill();
  }
}

dynamic _decodeUiExecutorArguments({required dynamic request}) =>
    (request as Map)[_args];

const extractInitialArguments = _decodeUiExecutorArguments;

Future _sendUiExecutorResponse({required request, required response}) async {
  final responsePort = request[_port] as SendPort;
  responsePort.send(response);
}

const _port = 'port';
const _args = 'args';
const _error = 'error';
const _stack = 'stack';
