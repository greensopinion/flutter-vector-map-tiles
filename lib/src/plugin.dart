import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/plugin_api.dart';

import 'grid/grid_layer.dart';
import 'options.dart';

class VectorMapTilesPlugin extends MapPlugin {
  @override
  Widget createLayer(
      LayerOptions options, MapState mapState, Stream<Null> stream) {
    if (options is VectorTileLayerOptions) {
      return VectorTileCompositeLayer(options, mapState, stream);
    }
    throw Exception('not supported: $options');
  }

  @override
  bool supportsLayer(LayerOptions options) {
    return options is VectorTileLayerOptions;
  }
}
