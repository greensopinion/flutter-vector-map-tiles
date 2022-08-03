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

  const VectorTileLayerWidget({super.key, required this.options});

  @override
  Widget build(BuildContext context) {
    final mapState = MapState.maybeOf(context)!;
    return VectorTileCompositeLayer(options: options, mapState: mapState);
  }
}
