import 'package:vector_tile_renderer/vector_tile_renderer.dart';

final defaultLayerPredicate = (Map<String, dynamic> layer) {
  final type = layer['type'];
  if (type == 'backgournd') {
    return true;
  } else if (type == 'fill') {
    final sourceLayer = layer['source-layer'];
    return (sourceLayer == 'landcover' ||
        sourceLayer == 'park' ||
        sourceLayer == 'water' ||
        sourceLayer == 'hillshade');
  }
  return false;
};

extension ThemeReaderExtension on ThemeReader {
  Theme readAsBackground(Map<String, dynamic> json,
      {required bool Function(Map<String, dynamic> layer) layerPredicate}) {
    final backgroundTheme = Map<String, dynamic>();
    json.entries.forEach((entry) {
      backgroundTheme[entry.key] = entry.value;
    });
    final layers = json['layers'] as List<dynamic>?;
    final newLayers = [];
    layers?.forEach((layer) {
      if (layer is Map<String, dynamic> && layerPredicate(layer)) {
        final type = layer['type'] as String?;
        if (type == 'background' || type == 'fill') {
          newLayers.add(layer);
        }
      }
    });
    backgroundTheme['layers'] = newLayers;
    return read(backgroundTheme);
  }
}
