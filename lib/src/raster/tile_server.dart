import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:async/async.dart';
import 'package:executor_lib/executor_lib.dart';
import 'package:flutter/src/painting/image_stream.dart';
import 'package:flutter_isolate/flutter_isolate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../../vector_map_tiles.dart';
import '../cache/cache_storage_function.dart';
import '../cache/caches.dart';
import '../grid/constants.dart';
import '../stream/caches_tile_provider.dart';
import '../stream/tile_processor.dart';
import '../stream/tileset_executor_preprocessor.dart';
import '../stream/tileset_ui_preprocessor.dart';
import '../stream/translating_tile_provider.dart';
import 'storage_image_cache.dart';
import 'tile_loader.dart';
import 'tile_protocol.dart';

class TileServer {
  bool _disposed = false;
  SendPort? _sendPort;
  StreamQueue<dynamic>? _stream;
  bool _isReady = false;
  final _ready = Completer<bool>();
  final _queue = <TileProtoRequest>[];
  final _responseByRequestId = <String, _OutstandingRequest>{};
  var _submitted = 0;

  TileServer() {
    _start();
    _receiveResults();
  }
  bool get disposed => _disposed;

  void dispose() {
    if (!_disposed) {
      _disposed = true;
      _sendPort?.send(null);
      _sendPort = null;
      _stream = null;
      _cancelAll();
    }
  }

  Future<TileProtoResponse> send(TileProtoRequest request) async {
    if (!_isReady) {
      await _ready.future;
    }
    if (disposed) {
      throw CancellationException();
    }
    final outstandingRequest = _OutstandingRequest(request: request);
    _responseByRequestId[request.requestId] = outstandingRequest;
    _queue.add(request);
    try {
      _submitOne();
    } catch (e) {
      _queue.remove(request);
      _responseByRequestId.remove(request.requestId);
      rethrow;
    }
    try {
      return await outstandingRequest.response.future;
    } finally {
      _responseByRequestId.remove(request.requestId);
    }
  }

  void _submitOne() {
    print('queue size: ${_queue.length} instance ${identityHashCode(this)}');
    if (_submitted < _concurrencyPerIsolate && _queue.isNotEmpty) {
      final request = _queue.removeLast(); //LIFO
      ++_submitted;
      try {
        final payload = request.toPayload();
        _sendPort!.send(payload);
      } catch (e) {
        --_submitted;
        rethrow;
      }
    }
  }

  void _start() async {
    final receivePort = ReceivePort();
    await FlutterIsolate.spawn(vectorMapTilesTileServer, receivePort.sendPort);
    _stream = StreamQueue<dynamic>(receivePort);
    final sendPort = (await _stream?.next) as SendPort;
    _sendPort = sendPort;
    _isReady = true;
    _ready.complete(true);
    if (_disposed) {
      sendPort.send(null);
      dispose();
    }
  }

  void _receiveResults() async {
    if (!_isReady) {
      await _ready.future;
    }
    while (true) {
      final stream = _stream;
      if (stream == null || _disposed) {
        return;
      }
      final result = await stream.next;
      if (result is Map) {
        --_submitted;
        final response = TileProtoResponse.fromPayload(result);
        final outstandingRequest =
            _responseByRequestId.remove(response.requestId);
        if (outstandingRequest != null &&
            !outstandingRequest.response.isCompleted) {
          print(
              'completed ${outstandingRequest.request.debugId()} in ${Duration(milliseconds: DateTime.now().millisecondsSinceEpoch - outstandingRequest.request.timestamp)} instance ${identityHashCode(this)}');
          outstandingRequest.response.complete(response);
        }
      }
      _submitOne();
    }
  }

  void _cancelAll() {
    _queue.clear();
    for (final outstandingRequest in _responseByRequestId.values) {
      if (!outstandingRequest.response.isCompleted) {
        outstandingRequest.response.completeError(CancellationException());
      }
    }
    _responseByRequestId.clear();
  }
}

@pragma('vm:entry-point')
void vectorMapTilesTileServer(SendPort port) async {
  final commandPort = ReceivePort();
  final commandStream = StreamQueue<dynamic>(commandPort);
  try {
    port.send(commandPort.sendPort);
    _CachesWithTileLoader? cachesWithTileLoader;
    while (true) {
      final command = await commandStream.next;
      if (command == null) {
        break;
      } else {
        final request = TileProtoRequest.fromPayload(command);
        print('starting ${request.debugId()}');
        if (request is LoadStyleFromUriRequest) {
          try {
            final style =
                await StyleReader(uri: request.uri, apiKey: request.apiKey)
                    .read();
            cachesWithTileLoader?.caches.dispose();
            cachesWithTileLoader = null;
            cachesWithTileLoader = await _createCachesWithTileLoader(
                style, TileOffset(zoomOffset: request.tileOffset));
            final payload = LoadStyleFromUriResponse(
                    requestId: request.requestId,
                    success: true,
                    errorMessage: null,
                    stack: null)
                .toPayload();
            port.send(payload);
          } catch (e, stack) {
            port.send(LoadStyleFromUriResponse(
                    requestId: request.requestId,
                    success: false,
                    errorMessage: e.toString(),
                    stack: stack.toString())
                .toPayload());
          }
        } else if (request is LoadThemeRequest) {
          try {
            final theme = ThemeReader().read(request.theme);
            final tileProviders = TileProviders(Map.fromEntries(
                request.tileProviders.entries.map((e) => MapEntry(
                    e.key,
                    NetworkVectorTileProvider(
                        urlTemplate: e.value.urlTemplate,
                        httpHeaders: e.value.httpHeaders,
                        maximumZoom: e.value.maximumZoom ?? 16,
                        minimumZoom: e.value.minimumZoom ?? 1)))));
            final style = Style(theme: theme, providers: tileProviders);
            cachesWithTileLoader?.caches.dispose();
            cachesWithTileLoader = null;
            cachesWithTileLoader = await _createCachesWithTileLoader(
                style, TileOffset(zoomOffset: request.tileOffset));
            port.send(LoadThemeResponse(
                    requestId: request.requestId,
                    success: true,
                    errorMessage: null,
                    stack: null)
                .toPayload());
          } catch (e, stack) {
            port.send(LoadThemeResponse(
                    requestId: request.requestId,
                    success: false,
                    errorMessage: e.toString(),
                    stack: stack.toString())
                .toPayload());
          }
        } else if (request is TileRequest) {
          final image = await cachesWithTileLoader!.tileLoader.loadTileImage(
              TileCoordinates(request.x, request.y, request.z),
              tileSize.x,
              () => false);
          _sendTileResponse(port, request, image);
        }
      }
    }
    cachesWithTileLoader?.caches.dispose();
  } finally {
    commandStream.cancel(immediate: true);
    commandPort.close();
  }
  FlutterIsolate.current.kill();
}

void _sendTileResponse(
    SendPort port, TileRequest request, ImageInfo image) async {
  try {
    final bytes = await image.image.toByteData(format: ImageByteFormat.png);
    if (bytes != null) {
      port.send(TileResponse(
              requestId: request.requestId,
              tileData: bytes.buffer.asUint8List(),
              success: true,
              errorMessage: null,
              stack: null)
          .toPayload());
    } else {
      throw Exception('No image bytes');
    }
  } catch (e, stack) {
    port.send(TileResponse(
            requestId: request.requestId,
            tileData: null,
            success: false,
            errorMessage: e.toString(),
            stack: stack.toString())
        .toPayload());
  } finally {
    image.dispose();
  }
}

class _CachesWithTileLoader {
  final Caches caches;
  final TileLoader tileLoader;

  _CachesWithTileLoader(this.caches, this.tileLoader);
}

const int _concurrencyPerIsolate = 3;

Future<_CachesWithTileLoader> _createCachesWithTileLoader(
    Style style, TileOffset tileOffset) async {
  final executor = PoolExecutor(concurrency: _concurrencyPerIsolate);
  final caches = Caches(
      providers: style.providers,
      executor: executor,
      theme: style.theme,
      sprites: style.sprites,
      ttl: VectorTileLayer.defaultCacheTtl,
      memoryTileCacheMaxSize: VectorTileLayer.defaultCacheMaxSize,
      memoryTileDataCacheMaxSize: VectorTileLayer.defaultTileDataCacheMaxSize,
      maxSizeInBytes: VectorTileLayer.defaultCacheMaxSize,
      maxTextCacheSize: VectorTileLayer.defaultTextCacheMaxSize,
      cacheStorage: cacheStorageResolver);
  final translatingTileProvider = TranslatingTileProvider(CachesTileProvider(
      caches,
      TileProcessor(executor),
      TilesetExecutorPreprocessor(TilesetPreprocessor(style.theme), executor),
      TilesetUiPreprocessor(
          TilesetPreprocessor(style.theme, initializeGeometry: true))));
  return _CachesWithTileLoader(
      caches,
      TileLoader(
          style.theme,
          style.sprites,
          caches.atlasImageCache?.retrieve,
          translatingTileProvider,
          tileOffset,
          StorageImageCache(style.theme, caches.storageCache),
          2));
}

class _OutstandingRequest {
  final TileProtoRequest request;
  final Completer<TileProtoResponse> response = Completer<TileProtoResponse>();

  _OutstandingRequest({required this.request});
}
