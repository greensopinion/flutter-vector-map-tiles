import 'package:flutter/widgets.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:vector_map_tiles/src/grid/grid_layer.dart';
import 'package:vector_map_tiles/src/options.dart';

class VectorTileLayerWidget extends StatelessWidget {
  final VectorTileLayerOptions options;

  const VectorTileLayerWidget({Key? key, required this.options})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mapState = MapState.maybeOf(context)!;
    return VectorTileLayer(options, mapState, mapState.onMoved);
  }
}
