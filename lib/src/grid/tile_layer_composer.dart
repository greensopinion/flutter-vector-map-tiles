import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../style/style.dart';
import 'tile_layer_model.dart';
import 'tile_model.dart';

class TileLayerComposer {
  List<TileLayerModel> compose(
      VectorTileModel vectorTileModel, Theme theme, SpriteStyle? sprites) {
    final layersByGroupId = <String, _Layer>{};
    var groupSeed = 0;
    String? currentGroupId;
    String currentGroupKey = 'none-$groupSeed';
    var currentGroup = _Layer(Duration.zero, Duration.zero);
    layersByGroupId[currentGroupKey] = currentGroup;
    for (final layer in theme.layers) {
      final groupId = layer.metadata[LayerMetadata.layerGroup];
      final newGroup = (groupId != currentGroupId);
      if (newGroup) {
        currentGroupId = groupId;
        currentGroupKey = groupId ?? 'none-${++groupSeed}';
        while (layersByGroupId.containsKey(currentGroupKey)) {
          ++groupSeed;
          currentGroupKey =
              (groupId == null) ? 'none-$groupSeed' : '$groupId-$groupSeed';
        }
        final layerDelay = layer.metadata[LayerMetadata.layerDelay];
        final layerInitialDelay =
            layer.metadata[LayerMetadata.layerInitialDelay] ?? layerDelay;
        currentGroup = _Layer(
            layerInitialDelay is num
                ? Duration(milliseconds: layerInitialDelay.toInt())
                : Duration.zero,
            layerDelay is num
                ? Duration(milliseconds: layerDelay.toInt())
                : Duration.zero);
        layersByGroupId[currentGroupKey] = currentGroup;
      }
      currentGroup.themeLayers.add(layer);
    }
    return layersByGroupId.entries
        .map((e) => TileLayerModel(
            tileModel: vectorTileModel,
            delay: e.value.delay,
            initialDelay: e.value.initialDelay,
            theme: Theme(
                id: '${theme.id}_${e.key}',
                layers: e.value.themeLayers,
                version: theme.version),
            sprites: sprites,
            id: '${theme.id}_${e.key}',
            tileset: null))
        .toList(growable: false);
  }
}

class LayerMetadata {
  static const prefix = 'vector_map_tiles';
  static const layerGroup = '$prefix:layer-group';
  static const layerInitialDelay = '$prefix:layer-initial-delay';
  static const layerDelay = '$prefix:layer-delay';
}

class _Layer {
  final Duration delay;
  final Duration initialDelay;
  final themeLayers = <ThemeLayer>[];

  _Layer(this.initialDelay, this.delay);
}
