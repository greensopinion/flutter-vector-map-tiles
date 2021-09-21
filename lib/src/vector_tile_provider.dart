import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:http/retry.dart';
import 'provider_exception.dart';

import 'cache/memory_cache.dart';
import 'tile_identity.dart';

abstract class VectorTileProvider {
  /// provides a tile as a `pbf` or `mvt` format
  Future<Uint8List> provide(TileIdentity tile);

  int get maximumZoom;
}

Duration _clientIdleTime = Duration(seconds: 10);
RetryClient? _retryClient;
DateTime _clientUsed = DateTime.now();
int _clientUsage = 0;

class NetworkVectorTileProvider extends VectorTileProvider {
  final _UrlProvider _urlProvider;
  final Map<String, String>? httpHeaders;
  final int _maximumZoom;

  int get maximumZoom => _maximumZoom;

  /// [urlTemplate] the URL template, e.g. `'https://tiles.stadiamaps.com/data/openmaptiles/{z}/{x}/{y}.pbf?api_key=$apiKey'`
  /// [httpHeaders] HTTP headers to include in requests, suitable for passing
  ///  `Authentication` header instead of an `api_key` in the URL template
  /// [maximumZoom] the maximum zoom supported by the tile provider, not to be
  ///  confused with the maximum zoom of the map widget. The map widget will
  ///  automatically use vector tiles from lower zoom levels once the maximum
  ///  supported by this provider is reached.
  NetworkVectorTileProvider(
      {required String urlTemplate, this.httpHeaders, int maximumZoom = 16})
      : _urlProvider = _UrlProvider(urlTemplate),
        _maximumZoom = maximumZoom;

  @override
  Future<Uint8List> provide(TileIdentity tile) async {
    _checkTile(tile);
    final uri = Uri.parse(_urlProvider.url(tile));
    try {
      ++_clientUsage;
      final client = _client();
      final response = await client.get(uri, headers: httpHeaders);
      _updateClientUsed();
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      throw ProviderException(
          message:
              'Cannot retrieve tile: HTTP ${response.statusCode}: $uri ${response.body}',
          retryable:
              response.statusCode == 503 ? Retryable.retry : Retryable.none);
    } on ClientException catch (e) {
      _updateClientUsed();
      throw ProviderException(message: e.message, retryable: Retryable.retry);
    } finally {
      --_clientUsage;
    }
  }

  void _checkTile(TileIdentity tile) {
    if (tile.z < 0 || tile.z > _maximumZoom || tile.x < 0 || tile.y < 0) {
      throw Exception('out of range');
    }
  }
}

void _updateClientUsed() {
  _clientUsed = DateTime.now();
}

RetryClient _client() {
  RetryClient? client = _retryClient;
  if (client == null) {
    client = RetryClient(Client(),
        when: _retryCondition, whenError: _retryErrorCondition);
    _retryClient = client;
    Future.delayed(_clientIdleTime, _expireClient);
  }
  _updateClientUsed();
  return client;
}

void _expireClient() {
  Duration elapsed = DateTime.now().difference(_clientUsed);
  if (elapsed > _clientIdleTime && _clientUsage == 0) {
    _retryClient?.close();
    _retryClient = null;
  } else {
    Future.delayed(
        Duration(milliseconds: (_clientIdleTime.inMilliseconds / 2).floor()),
        _expireClient);
  }
}

bool _retryCondition(BaseResponse response) =>
    response.statusCode == 503 || response.statusCode == 408;

bool _retryErrorCondition(Object error, StackTrace stack) =>
    error is SocketException;

class MemoryCacheVectorTileProvider extends VectorTileProvider {
  final VectorTileProvider delegate;
  late final MemoryCache _cache;

  int get maximumZoom => delegate.maximumZoom;

  MemoryCacheVectorTileProvider(
      {required this.delegate, required int maxSizeBytes}) {
    _cache = MemoryCache(maxSizeBytes: maxSizeBytes);
  }

  @override
  Future<Uint8List> provide(TileIdentity tile) async {
    final key = tile.toCacheKey();
    var value = _cache.getItem(key);
    if (value == null) {
      value = await delegate.provide(tile);
      _cache.putItem(key, value);
    }
    return value;
  }
}

class _UrlProvider {
  final String urlTemplate;

  _UrlProvider(this.urlTemplate);

  String url(TileIdentity identity) {
    return urlTemplate.replaceAllMapped(RegExp(r'\{(x|y|z)\}'), (match) {
      switch (match.group(1)) {
        case 'x':
          return identity.x.toInt().toString();
        case 'y':
          return identity.y.toInt().toString();
        case 'z':
          return identity.z.toInt().toString();
        default:
          throw Exception(
              'unexpected url template: $urlTemplate - token ${match.group(1)} is not supported');
      }
    });
  }
}

extension _TileCacheKey on TileIdentity {
  String toCacheKey() => '$z.$x.$y';
}
