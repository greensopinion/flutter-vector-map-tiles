import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/plugin_api.dart';

import 'grid/grid_layer.dart';
import 'options.dart';

class VectorMapTilesPlugin extends MapPlugin {
  @override
  Widget createLayer(
      LayerOptions options, MapState mapState, Stream<void> stream) {
    if (options is VectorTileLayerOptions) {
      _checkZoomDifference(mapState, options);
      return VectorTileCompositeLayer(options, mapState, stream);
    }
    throw Exception('not supported: $options');
  }

  @override
  bool supportsLayer(LayerOptions options) {
    return options is VectorTileLayerOptions;
  }

  void _checkZoomDifference(MapState mapState, VectorTileLayerOptions options) {
    final maxTileProviderZoom = options
        .tileProviders.tileProviderBySource.values
        .map((e) => e.maximumZoom)
        .reduce(max);
    final mapMaxZoom = mapState.options.maxZoom ?? maxTileProviderZoom;
    final difference = (mapMaxZoom - maxTileProviderZoom).abs();
    if (difference > options.maximumZoomDifference) {
      throw 'Tile providers have a maximumZoom of $maxTileProviderZoom with map maximum zoom of $mapMaxZoom, ' +
          'a difference of $difference which exceeds the maximum configured difference of ${options.maximumZoomDifference}. ' +
          'A large difference in zoom levels can lead to application crashes due to lack of memory. ' +
          'Consider setting MapOptions.maxZoom to ${maxTileProviderZoom + options.maximumZoomDifference} or increase ' +
          'the maximumZoom of your TileProvider. If you are sure that you want to use a lot of memory, you can set ' +
          'VectorTileLayerOptions.maximumZoomDifference to ${mapMaxZoom - maxTileProviderZoom} or higher ' +
          'to avoid this error. See issue #24 for details.';
    }
  }
}
