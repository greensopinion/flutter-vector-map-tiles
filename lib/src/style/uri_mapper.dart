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
}

String _replaceKey(String url, String? key) {
  return url.replaceAll(
      RegExp(RegExp.escape(_keyToken)), Uri.encodeQueryComponent(key ?? ''));
}

const _keyToken = '{key}';
