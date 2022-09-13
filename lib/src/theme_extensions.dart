import 'package:vector_tile_renderer/vector_tile_renderer.dart';

/// accepts layers that are:
///
/// * of type `background`
/// * of type `fill` that use source layer `landcover` or `water`
///
bool defaultBackgroundLayerPredicate(Map<String, dynamic> layer) {
  final type = layer['type'];
  if (type == 'background') {
    return true;
  } else if (type == 'fill') {
    final sourceLayer = layer['source-layer'];
    return (sourceLayer == 'landcover' || sourceLayer == 'water');
  }
  return false;
}

extension ThemeReaderExtension on ThemeReader {
  /// reads a theme for use as a background theme
  Theme readAsBackground(Map<String, dynamic> json,
      {required bool Function(Map<String, dynamic> layer) layerPredicate}) {
    final backgroundTheme = <String, dynamic>{};
    for (final entry in json.entries) {
      backgroundTheme[entry.key] = entry.value;
    }
    final layers = json['layers'] as List<dynamic>?;
    final newLayers = [];
    layers?.forEach((layer) {
      if (layer is Map<String, dynamic> && layerPredicate(layer)) {
        newLayers.add(layer);
      }
    });
    backgroundTheme['id'] = (json['id'] ?? 'default') + '_bg';
    backgroundTheme['layers'] = newLayers;
    return read(backgroundTheme);
  }
}
