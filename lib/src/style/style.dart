import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:latlong2/latlong.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../provider/network_vector_tile_provider.dart';
import '../tile_providers.dart';
import '../vector_tile_provider.dart';
import 'uri_mapper.dart';

class Style {
  final String? name;
  final Theme theme;
  final TileProviders providers;
  final SpriteStyle? sprites;
  final LatLng? center;
  final double? zoom;

  Style(
      {this.name,
      required this.theme,
      required this.providers,
      this.sprites,
      this.center,
      this.zoom});
}

class SpriteStyle {
  final Future<Uint8List> Function() atlasProvider;
  final SpriteIndex index;

  SpriteStyle({required this.atlasProvider, required this.index});
}

abstract class BaseStyleReader {
  final String? apiKey;
  final Logger logger;
  final Map<String, String>? httpHeaders;

  BaseStyleReader({this.apiKey, Logger? logger, this.httpHeaders})
      : logger = logger ?? const Logger.noop();

  Future<Style> read();

  String? getName(Map<String, dynamic> style) {
    return style['name'] as String?;
  }

  LatLng? getCenter(Map<String, dynamic> style) {
    final center = style['center'];
    if (center is List && center.length == 2) {
      return LatLng(
          (center[1] as num).toDouble(), (center[0] as num).toDouble());
    }
    return null;
  }

  double? getZoom(Map<String, dynamic> style) {
    return (style['zoom'] as num?)?.toDouble();
  }

  Future<SpriteStyle?> getSprite(
      String? uri, Map<String, dynamic> style, StyleUriMapper uriMapper) async {
    final spriteUri = style['sprite'];
    if (spriteUri is String && spriteUri.trim().isNotEmpty) {
      final spriteUris = uriMapper.mapSprite(uri, spriteUri);
      for (final spriteUri in spriteUris) {
        dynamic spritesJson;
        try {
          final spritesJsonText = await _httpGet(spriteUri.json, httpHeaders);
          spritesJson = await compute(jsonDecode, spritesJsonText);
        } catch (e) {
          logger.log(() => 'error reading sprite uri: ${spriteUri.json}');
          continue;
        }
        return SpriteStyle(
            atlasProvider: () => _loadBinary(spriteUri.image, httpHeaders),
            index: SpriteIndexReader(logger: logger).read(spritesJson));
      }
    }

    return null;
  }

  Future<TileProviders> getTileProviders(
      String? uri, Map<String, dynamic> style) async {
    final sources = style['sources'];
    if (sources is! Map) {
      throw _invalidStyle(uri);
    }

    final providerByName = await _readProviderByName(uri, sources);

    return TileProviders(providerByName);
  }

  Future<Map<String, VectorTileProvider>> _readProviderByName(
      String? uri, Map sources) async {
    final providers = <String, VectorTileProvider>{};
    final sourceEntries = sources.entries.toList();
    for (final entry in sourceEntries) {
      final sourceType = entry.value['type'];
      var type = TileProviderType.values
          .where((e) => e.name.replaceAll('_', '-') == sourceType)
          .firstOrNull;
      if (type == null) continue;
      dynamic source;
      var entryUrl = entry.value['url'] as String?;
      if (entryUrl != null) {
        final sourceUrl = StyleUriMapper(key: apiKey).mapSource(uri, entryUrl);
        source =
            await compute(jsonDecode, await _httpGet(sourceUrl, httpHeaders));
        if (source is! Map) {
          throw _invalidStyle(sourceUrl);
        }
      } else {
        source = entry.value;
      }
      final entryTiles = source['tiles'];
      final maxzoom = source['maxzoom'] as int? ?? 14;
      final minzoom = source['minzoom'] as int? ?? 1;
      if (entryTiles is List && entryTiles.isNotEmpty) {
        final tileUri = entryTiles[0] as String;
        final tileUrl = StyleUriMapper(key: apiKey).mapTiles(tileUri);
        providers[entry.key] = NetworkVectorTileProvider(
            type: type,
            urlTemplate: tileUrl,
            maximumZoom: maxzoom,
            minimumZoom: minzoom,
            httpHeaders: httpHeaders);
      }
    }
    if (providers.isEmpty) {
      throw 'Unexpected response';
    }
    return providers;
  }
}

class StyleReader extends BaseStyleReader {
  final String uri;

  StyleReader(
      {required this.uri, super.apiKey, super.logger, super.httpHeaders});

  @override
  Future<Style> read() async {
    final uriMapper = StyleUriMapper(key: apiKey);
    final url = uriMapper.map(uri);
    final styleText = await _httpGet(url, httpHeaders);
    final style = await compute(jsonDecode, styleText);
    if (style is! Map<String, dynamic>) {
      throw _invalidStyle(url);
    }

    LatLng? centerPoint = getCenter(style);
    double? zoom = getZoom(style);

    if (zoom != null && zoom < 2) {
      zoom = null;
      centerPoint = null;
    }

    return Style(
        theme: ThemeReader(logger: logger).read(style),
        providers: await getTileProviders(url, style),
        sprites: await getSprite(uri, style, uriMapper),
        name: getName(style),
        center: centerPoint,
        zoom: zoom);
  }
}

class LocalStyleReader extends BaseStyleReader {
  final Map<String, dynamic> styleJson;

  LocalStyleReader(
      {required this.styleJson, super.apiKey, super.logger, super.httpHeaders});

  @override
  Future<Style> read() async {
    final uriMapper = StyleUriMapper(key: apiKey);
    final style = styleJson;

    LatLng? centerPoint = getCenter(style);
    double? zoom = getZoom(style);

    if (zoom != null && zoom < 2) {
      zoom = null;
      centerPoint = null;
    }

    return Style(
        theme: ThemeReader(logger: logger).read(style),
        providers: await getTileProviders(null, style),
        sprites: await getSprite(null, style, uriMapper),
        name: getName(style),
        center: centerPoint,
        zoom: zoom);
  }
}

String _invalidStyle(String? url) {
  if (url != null) {
    return 'Uri does not appear to be a valid style: $url';
  }
  return 'Style json does not appear to be valid.';
}

Future<String> _httpGet(String url, Map<String, String>? httpHeaders) async {
  final response = await get(Uri.parse(url), headers: httpHeaders);
  if (response.statusCode == 200) {
    return response.body;
  } else {
    throw 'HTTP ${response.statusCode}: ${response.body}';
  }
}

Future<Uint8List> _loadBinary(
    String url, Map<String, String>? httpHeaders) async {
  final response = await get(Uri.parse(url), headers: httpHeaders);
  if (response.statusCode == 200) {
    return response.bodyBytes;
  } else {
    throw 'HTTP ${response.statusCode}: ${response.body}';
  }
}
