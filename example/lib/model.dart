import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:vector_map_tiles_example/api_key.dart';
import 'package:http/http.dart' as http;
import 'package:vector_tile_renderer/vector_tile_renderer.dart' as vt;

class MapModel extends ChangeNotifier {
  bool loading = false;
  vt.Theme? theme;

  Future<void> load() async {
    final client = http.Client();
    try {
      loading = true;
      final response = await client.get(Uri.parse(
          "https://api.mapbox.com/styles/v1/mapbox/streets-v11/?access_token=$mapboxApiKey"));
      if (response.statusCode == 200) {
        final style = jsonDecode(response.body);
        theme = vt.ThemeReader().read(style);
        notifyListeners();
      }
    } finally {
      loading = false;
      client.close();
    }
  }

  VectorTileProvider tileProvider() => _cachingTileProvider(_urlTemplate());
}

String _urlTemplate() =>
    'https://api.mapbox.com/v4/mapbox.mapbox-streets-v8/{z}/{x}/{y}.mvt?access_token=$mapboxApiKey';

VectorTileProvider _cachingTileProvider(String urlTemplate) {
  return MemoryCacheVectorTileProvider(
      delegate:
          NetworkVectorTileProvider(urlTemplate: urlTemplate, maximumZoom: 22),
      maxSizeBytes: 1024 * 1024 * 2);
}
