import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import 'raster/isolate_tile_loader.dart';

export 'raster/isolate_tile_loader.dart'
    show renderTileEntrypoint, EntrypointFunction, StyleFunction;
export 'raster/ui_isolate_executor.dart' show extractInitialArguments;

/// Experimental
class RasterTileLayer extends StatefulWidget {
  final EntrypointFunction entrypoint;
  final Map? entrypointParamters;

  const RasterTileLayer(
      {super.key, required this.entrypoint, this.entrypointParamters});

  @override
  State<StatefulWidget> createState() => _RasterTileLayer();
}

class _RasterTileLayer extends State<RasterTileLayer> {
  late IsolateTileLoader _tileLoader;
  late TileProvider _tileProvider;
  var _generation = 0;

  @override
  void initState() {
    super.initState();
    _tileLoader = IsolateTileLoader(
        entrypoint: widget.entrypoint,
        entrypointParamters: widget.entrypointParamters);
    _tileProvider = _tileLoader.provider();
  }

  @override
  void didUpdateWidget(RasterTileLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!mapEquals(oldWidget.entrypointParamters, widget.entrypointParamters)) {
      final oldLoader = _tileProvider;
      setState(() {
        ++_generation;
        oldLoader.dispose();
        _tileLoader = IsolateTileLoader(
            entrypoint: widget.entrypoint,
            entrypointParamters: widget.entrypointParamters);
        _tileProvider = _tileLoader.provider();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return TileLayer(
        key: Key('${widget.key}_tileLayer_$_generation'),
        tileProvider: _tileProvider);
  }

  @override
  void dispose() {
    _tileProvider.dispose();
    super.dispose();
  }
}
