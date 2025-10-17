import 'dart:async';

import 'package:executor_lib/executor_lib.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:vector_map_tiles/src/model/tile_data_model.dart';

import '../executors/executors_std.dart';
import '../loader/theme_repo.dart';
import '../loader/tile_loader.dart';
import '../model/map_properties.dart';
import '../model/map_tiles.dart';
import 'flutter_map_adapter.dart';

abstract class AbstractMapLayer extends StatefulWidget {
  final MapProperties mapProperties;
  final TileLoader Function(MapProperties, Executor, ThemeRepo) tileLoaderFactory;

  const AbstractMapLayer({
    super.key,
    required this.mapProperties,
    required this.tileLoaderFactory,
  });
}

abstract class AbstractMapLayerState<T extends AbstractMapLayer>
    extends State<T> with SingleTickerProviderStateMixin {
  late final Executor executor;
  late final TileLoader tileLoader;
  late final MapTiles mapTiles;
  FlutterMapAdapter? _mapAdapter;
  Ticker? _animationTicker;
  DateTime? _animationEndTime;

  @override
  void dispose() {
    _animationTicker?.dispose();
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

  void onTilesChanged() {
    _startAnimationPeriod();
  }

  void _startAnimationPeriod() {
    final now = DateTime.now();
    final endTime = now.add(const Duration(milliseconds: 1000));

    if (_animationEndTime == null || endTime.isAfter(_animationEndTime!)) {
      _animationEndTime = endTime;
    }

    if (_animationTicker == null) {
      _animationTicker = createTicker(_onAnimationTick);
      _animationTicker!.start();
    } else if (!_animationTicker!.isActive) {
      _animationTicker!.start();
    }
  }

  void _onAnimationTick(Duration elapsed) {
    final now = DateTime.now();

    if (_animationEndTime != null && now.isBefore(_animationEndTime!)) {
      if (mounted) {
        setState(() {});
      }
    } else {
      _animationTicker?.stop();
      _animationEndTime = null;
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
    tileLoader = widget.tileLoaderFactory(widget.mapProperties, executor, ThemeRepo());
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
