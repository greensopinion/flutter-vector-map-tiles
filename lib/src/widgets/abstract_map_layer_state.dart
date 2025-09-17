import 'package:executor_lib/executor_lib.dart';
import 'package:flutter/widgets.dart';
import 'package:vector_map_tiles/src/model/tile_data_model.dart';

import '../executors/executors_std.dart';
import '../loader/tile_loader.dart';
import '../model/map_properties.dart';
import '../model/map_tiles.dart';
import 'flutter_map_adapter.dart';

abstract class AbstractMapLayer extends StatefulWidget {
  final MapProperties mapProperties;
  final TileLoader Function(MapProperties, Executor) tileLoaderFactory;

  const AbstractMapLayer({
    super.key,
    required this.mapProperties,
    required this.tileLoaderFactory,
  });
}

abstract class AbstractMapLayerState<T extends AbstractMapLayer>
    extends State<T> {
  late final Executor executor;
  late final TileLoader tileLoader;
  late final MapTiles mapTiles;
  FlutterMapAdapter? _mapAdapter;

  @override
  void dispose() {
    executor.dispose();
    _mapAdapter?.dispose();
    super.dispose();
  }

  double get zoom => _mapAdapter?.zoom ?? 1.0;
  double get rotation => _mapAdapter?.rotation ?? 0.0;

  void updateTiles(BuildContext context) {
    _updateTiles();
    _mapAdapter?.update(context);
  }

  void _updateTiles() {
    for (final tile in mapTiles.tileModels.where(
      (model) => model.isLoaded && !model.isDisplayReady && !model.preRenderStarted
    )) {
      preRender(tile).then((_) {
        if (mounted) {
          setState(() {
            tile.isDisplayReady = tile.isLoaded;
          });
        }
      });
    }
  }

  Future<void> preRender(TileDataModel tile) => Future.sync(() {
    tile.preRenderStarted = true;
  });

  void resetState() {
    mapTiles.dispose();
    mapTiles = MapTiles(tileLoader: tileLoader);
    mapTiles.addListener(_updateTiles);
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    executor = newConcurrentExecutor(
      concurrency: widget.mapProperties.concurrency,
    );
    tileLoader = widget.tileLoaderFactory(widget.mapProperties, executor);
    mapTiles = MapTiles(tileLoader: tileLoader);
    _mapAdapter ??= FlutterMapAdapter(
      mapTiles: mapTiles,
      mapUpdated: _mapUpdated,
      tileOffset: widget.mapProperties.tileOffset,
    );
    mapTiles.addListener(_updateTiles);
  }

  void _mapUpdated() {
    if (mounted) {
      setState(() {});
    }
  }
}
