import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';

import '../vector_map_tiles.dart';
import 'grid/grid_layer.dart';

/// A widget for a vector tile layer, to be used as a child
/// of a [FlutterMap].
/// See readme for details.
/// See [VectorTileLayerOptions] for an alternative.
class VectorTileLayerWidget extends StatelessWidget {
  final VectorTileLayerOptions options;

  const VectorTileLayerWidget({Key? key, required this.options})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mapState = MapState.maybeOf(context)!;
    return VectorTileCompositeLayer(options, mapState, mapState.onMoved);
  }
}
