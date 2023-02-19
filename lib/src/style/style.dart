import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:latlong2/latlong.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../tile_providers.dart';
import '../vector_tile_provider.dart';
import 'uri_mapper.dart';

class Style {
  final String? name;
  final Theme theme;
  final TileProviders providers;
  final LatLng? center;
  final double? zoom;

  Style(
      {this.name,
      required this.theme,
      required this.providers,
      this.center,
      this.zoom});
}

class StyleReader {
  final String uri;
  final String? apiKey;
  final Logger logger;

  StyleReader({required this.uri, this.apiKey, Logger? logger})
      : logger = logger ?? const Logger.noop();

  Future<Style> read() async {
    final url = StyleUriMapper(key: apiKey).map(uri);
    final styleText = await _httpGet(url);
    final style = await compute(jsonDecode, styleText);
    if (style is! Map<String, dynamic>) {
      throw _invalidStyle(url);
    }
    final sources = style['sources'];
    if (sources is! Map) {
      throw _invalidStyle(url);
    }
    final providerByName = await _readProviderByName(sources);
    final name = style['name'] as String?;

    final center = style['center'];
    LatLng? centerPoint;
    if (center is List && center.length == 2) {
      centerPoint =
          LatLng((center[1] as num).toDouble(), (center[0] as num).toDouble());
    }
    double? zoom = (style['zoom'] as num?)?.toDouble();
    if (zoom != null && zoom < 2) {
      zoom = null;
      centerPoint = null;
    }
    return Style(
        theme: ThemeReader(logger: logger).read(style),
        providers: TileProviders(providerByName),
        name: name,
        center: centerPoint,
        zoom: zoom);
  }

  Future<Map<String, VectorTileProvider>> _readProviderByName(
      Map sources) async {
    final providers = <String, VectorTileProvider>{};
    final sourceEntries = sources.entries
        .where((s) => s.value['type'] == 'vector' && s.value['url'] is String)
        .toList();
    for (final entry in sourceEntries) {
      var entryUrl = entry.value['url'] as String;
      final sourceUrl = StyleUriMapper(key: apiKey).mapSource(uri, entryUrl);
      final source = await compute(jsonDecode, await _httpGet(sourceUrl));
      if (source is! Map) {
        throw _invalidStyle(sourceUrl);
      }
      final entryTiles = source['tiles'];
      final maxzoom = source['maxzoom'] as int? ?? 14;
      if (entryTiles is List && entryTiles.isNotEmpty) {
        final tileUri = entryTiles[0] as String;
        final tileUrl = StyleUriMapper(key: apiKey).mapTiles(tileUri);
        providers[entry.key] = NetworkVectorTileProvider(
            urlTemplate: tileUrl, maximumZoom: maxzoom);
      }
    }
    if (providers.isEmpty) {
      throw 'Unexpected response';
    }
    return providers;
  }
}

String _invalidStyle(String url) =>
    'Uri does not appear to be a valid style: $url';

Future<String> _httpGet(String url) async {
  final response = await get(Uri.parse(url));
  if (response.statusCode == 200) {
    return response.body;
  } else {
    throw 'HTTP ${response.statusCode}: ${response.body}';
  }
}
