import 'dart:typed_data';

import 'package:latlong2/latlong.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

/// Helper class to serialize style objects to be able to read and write them from and to disk.
class StyleSerializer {
  static Style fromJson(Map<String, dynamic> json, {required Theme theme}) {
    final centerJson = json['center'];

    return Style(
      name: json['name'],
      theme: theme,
      providers: _TileProvidersSerializer.fromJson(json['providers']),
      sprites: _SpriteStyleSerializer.fromJson(json['sprites']),
      center: centerJson != null ? LatLng.fromJson(json['center']) : null,
      zoom: json['zoom'],
    );
  }

  static Future<Map<String, dynamic>> toJson(Style style) async {
    return {
      'name': style.name,
      'providers': _TileProvidersSerializer.toJson(style.providers),
      'sprites': style.sprites != null
          ? await _SpriteStyleSerializer.toJson(style.sprites!)
          : null,
      'center': style.center?.toJson(),
      'zoom': style.zoom,
    };
  }
}

class _TileProvidersSerializer {
  static TileProviders fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> tileProviderBySourceJson =
        json['tileProviderBySource'];
    final Map<String, VectorTileProvider> tileProviders =
        tileProviderBySourceJson.map(
      (key, value) {
        return MapEntry(
            key, _NetworkVectorTileProviderSerializer.fromJson(value));
      },
    );

    return TileProviders(tileProviders);
  }

  static Map<String, dynamic> toJson(TileProviders providers) {
    return {
      'tileProviderBySource':
          providers.tileProviderBySource.map((key, provider) {
        final providerJson = switch (provider) {
          NetworkVectorTileProvider provider =>
            _NetworkVectorTileProviderSerializer.toJson(provider),
          _ => UnimplementedError(
              'Tried converting a tile provider into json that is not implemented!'),
        };

        return MapEntry(key, providerJson);
      }),
    };
  }
}

class _NetworkVectorTileProviderSerializer {
  static NetworkVectorTileProvider fromJson(Map<String, dynamic> json) {
    return NetworkVectorTileProvider(
      urlTemplate: json['urlTemplate'],
      type: TileProviderType.values[json['typeIndex']],
      httpHeaders: Map<String, String>.from(json['httpHeaders']),
      maximumZoom: json['maximumZoom'],
      minimumZoom: json['minimumZoom'],
    );
  }

  static Map<String, dynamic> toJson(NetworkVectorTileProvider provider) {
    return {
      'typeIndex': provider.type.index,
      'urlTemplate': provider.urlTemplate,
      'httpHeaders': provider.httpHeaders,
      'maximumZoom': provider.maximumZoom,
      'minimumZoom': provider.minimumZoom,
    };
  }
}

class _SpriteStyleSerializer {
  static SpriteStyle fromJson(Map<String, dynamic> json) {
    return SpriteStyle(
      atlasProvider: () async {
        return Uint8List.fromList((json['atlas']));
      },
      index: _SpriteIndexSerializer.fromJson(json['index']),
    );
  }

  static Future<Map<String, dynamic>> toJson(SpriteStyle spriteStyle) async {
    final atlas = await spriteStyle.atlasProvider();

    return {
      'atlas': atlas.toList(),
      'index': _SpriteIndexSerializer.toJson(spriteStyle.index),
    };
  }
}

class _SpriteIndexSerializer {
  static SpriteIndex fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> spriteByNameJson = json['spriteByName'];
    final Map<String, Sprite> spriteByName = spriteByNameJson.map(
      (key, value) {
        return MapEntry(key, _SpriteSerializer.fromJson(value));
      },
    );

    return SpriteIndex(spriteByName);
  }

  static Map<String, dynamic> toJson(SpriteIndex index) {
    return {
      'spriteByName': index.spriteByName.map((key, sprite) {
        return MapEntry(key, _SpriteSerializer.toJson(sprite));
      })
    };
  }
}

class _SpriteSerializer {
  static Sprite fromJson(Map<String, dynamic> json) {
    final stretchXJson = json['stretchX'];
    final stretchYJson = json['stretchY'];

    return Sprite(
      name: json['name'],
      width: json['width'],
      height: json['height'],
      x: json['x'],
      y: json['y'],
      pixelRatio: json['pixelRatio'],
      content: json['content']?.cast<int>(),
      stretchX: List.generate(
        stretchXJson.length,
        (index) => stretchXJson[index].cast<int>(),
      ),
      stretchY: List.generate(
        stretchYJson.length,
        (index) => stretchYJson[index].cast<int>(),
      ),
    );
  }

  static Map<String, dynamic> toJson(Sprite sprite) {
    return {
      'name': sprite.name,
      'width': sprite.width,
      'height': sprite.height,
      'x': sprite.x,
      'y': sprite.y,
      'pixelRatio': sprite.pixelRatio,
      'content': sprite.content,
      'stretchX': sprite.stretchX,
      'stretchY': sprite.stretchY,
    };
  }
}
