class StyleUriMapper {
  final String? _key;

  StyleUriMapper({String? key}) : _key = key;

  String map(String uri) {
    var mapped = uri;
    final parsed = Uri.parse(uri);
    if (parsed.scheme == 'mapbox') {
      mapped = _toMapboxStyleApiUri(uri);
    }
    mapped = _replaceKey(mapped, _key);
    return mapped;
  }

  String mapSource(String styleUri, String sourceUri) {
    final parameters = Uri.parse(map(styleUri)).queryParameters;
    final parsed = Uri.parse(sourceUri);
    var mapped = sourceUri;
    if (parsed.scheme == 'mapbox') {
      mapped = _toMapboxSourceApiUri(mapped, parameters);
    } else {
      mapped = _replaceKey(mapped, _key);
    }
    return mapped;
  }

  List<SpriteUri> mapSprite(String styleUri, String spriteUri) {
    final parameters = Uri.parse(map(styleUri)).queryParameters;
    final parsed = Uri.parse(spriteUri);
    final uris = <SpriteUri>[];
    if (parsed.scheme == 'mapbox') {
      uris.add(_toMapboxSpriteUri(spriteUri, parameters, '@2x'));
      uris.add(_toMapboxSpriteUri(spriteUri, parameters, ''));
    } else {
      final parameters = Uri.parse(map(styleUri)).queryParameters;
      uris.add(_toSpriteUri(spriteUri, parameters, '@2x'));
      uris.add(_toSpriteUri(spriteUri, parameters, ''));
    }
    return uris;
  }

  String mapTiles(String tileUri) {
    return _replaceKey(tileUri, _key);
  }

  String _toMapboxStyleApiUri(String uri) {
    final match =
        RegExp(r'mapbox://styles/([^/]+)/([^?]+)\??(.+)?').firstMatch(uri);
    if (match == null) {
      throw 'Unexpected format: $uri';
    }
    final username = match.group(1);
    final styleId = match.group(2);
    final parameters = match.group(3);
    var apiUri = 'https://api.mapbox.com/styles/v1/$username/$styleId';
    if (parameters != null && parameters.isNotEmpty) {
      apiUri = '$apiUri?$parameters';
    }
    return apiUri;
  }

  String _toMapboxSourceApiUri(
      String sourceUri, Map<String, String> parameters) {
    final match = RegExp(r'mapbox://(.+)').firstMatch(sourceUri);
    if (match == null) {
      throw 'Unexpected format: $sourceUri';
    }
    final style = match.group(1);
    return 'https://api.mapbox.com/v4/$style.json?secure&${parameters.entries.map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}').join('&')}';
  }

  SpriteUri _toMapboxSpriteUri(
      String spriteUri, Map<String, String> parameters, String suffix) {
    final match = RegExp(r'mapbox://sprites/(.+)').firstMatch(spriteUri);
    if (match == null) {
      throw 'Unexpected format: $spriteUri';
    }
    final sprite = match.group(1);
    return SpriteUri(
        json:
            'https://api.mapbox.com/styles/v1/$sprite/sprite$suffix.json?secure&${parameters.entries.map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}').join('&')}',
        image:
            'https://api.mapbox.com/styles/v1/$sprite/sprite$suffix.png?secure&${parameters.entries.map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}').join('&')}');
  }

  SpriteUri _toSpriteUri(
      String spriteUri, Map<String, String> parameters, String suffix) {
    return SpriteUri(
        json:
            '$spriteUri$suffix.json?secure&${parameters.entries.map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}').join('&')}',
        image:
            '$spriteUri$suffix.png?secure&${parameters.entries.map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}').join('&')}');
  }
}

String _replaceKey(String url, String? key) {
  return url.replaceAll(
      RegExp(RegExp.escape(_keyToken)), Uri.encodeQueryComponent(key ?? ''));
}

const _keyToken = '{key}';

class SpriteUri {
  final String json;
  final String image;

  SpriteUri({required this.json, required this.image});
}
