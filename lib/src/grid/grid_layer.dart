import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:vector_map_tiles/src/executor/direct_executor.dart';
import 'package:vector_map_tiles/src/executor/pool_executor.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../cache/caches.dart';
import '../executor/executor.dart';
import '../options.dart';
import '../stream/caches_tile_provider.dart';
import '../stream/preprocessing_tile_provider.dart';
import '../stream/provider_supplier.dart';
import '../stream/tile_supplier.dart';
import '../tile_identity.dart';
import 'debounce.dart';
import 'disposable_state.dart';
import 'grid_tile_positioner.dart';
import 'renderer_pipeline.dart';
import 'tile_widgets.dart';

class VectorTileCompositeLayer extends StatefulWidget {
  final VectorTileLayerOptions options;
  final MapState mapState;
  final Stream<Null> stream;

  const VectorTileCompositeLayer(this.options, this.mapState, this.stream);

  @override
  State<StatefulWidget> createState() {
    return _VectorTileCompositeLayerState();
  }
}

class _VectorTileCompositeLayerState extends State<VectorTileCompositeLayer>
    with WidgetsBindingObserver {
  late Executor _executor;
  late Caches _caches;
  late TileSupplier _tileSupplier;
  late final _cacheStats = ScheduledDebounce(_printCacheStats,
      delay: Duration(seconds: 1),
      jitter: Duration(milliseconds: 0),
      maxAge: Duration(seconds: 3));
  StreamSubscription<Null>? _subscription;

  @override
  void initState() {
    super.initState();
    _executor = newExecutor();
    _createCaches();
    Future.delayed(Duration(seconds: 3), () {
      _caches.applyConstraints();
    });
    if (widget.options.logCacheStats) {
      _subscription = widget.stream.listen((event) {
        _cacheStats.update();
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    _subscription?.cancel();
    _caches.dispose();
    _executor.dispose();
  }

  @override
  void didHaveMemoryPressure() {
    _caches.didHaveMemoryPressure();
  }

  @override
  void didUpdateWidget(covariant VectorTileCompositeLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.options.theme.id != widget.options.theme.id) {
      setState(() {
        _caches.dispose();
        _createCaches();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = widget.options;
    final backgroundTheme = options.backgroundTheme;
    final layers = <Widget>[
      VectorTileLayer(
          Key("${options.theme.id}_VectorTileLayer"),
          _LayerOptions(
              options.theme,
              options.renderMode,
              options.showTileDebugInfo,
              backgroundTheme == null,
              false,
              () => widget.mapState.zoom),
          widget.mapState,
          widget.stream,
          _tileSupplier)
    ];
    if (backgroundTheme != null) {
      final background = VectorTileLayer(
          Key("${backgroundTheme.id}_background_VectorTileLayer"),
          _LayerOptions(backgroundTheme, RenderMode.vector,
              options.showTileDebugInfo, true, true, _backgroundZoom),
          widget.mapState,
          widget.stream,
          _tileSupplier);
      layers.insert(0, background);
    }
    return Stack(children: layers);
  }

  void _createCaches() {
    _caches = Caches(
        executor: _executor,
        providers: widget.options.tileProviders,
        pipeline: RendererPipeline(widget.options.theme,
            scale: widget.options.rasterImageScale),
        ttl: widget.options.fileCacheTtl,
        maxTilesInMemory: widget.options.maxTilesInMemory,
        maxImagesInMemory: widget.options.maxImagesInMemory,
        maxSizeInBytes: widget.options.fileCacheMaximumSizeInBytes);
    _tileSupplier = ProviderTileSupplier(PreprocessingTileProvider(
        CachesTileProvider(_caches),
        TilesetPreprocessor(widget.options.theme),
        _executor));
  }

  void _printCacheStats() {
    print('Cache stats:\n${_caches.stats()}');
  }

  double _backgroundZoom() {
    return max(1, min(14, widget.mapState.zoom - 2).roundToDouble());
  }
}

class _LayerOptions {
  final Theme theme;
  final RenderMode renderMode;
  final bool showTileDebugInfo;
  final bool paintBackground;
  final bool paintNoDataTiles;
  final double Function() mapZoom;

  _LayerOptions(this.theme, this.renderMode, this.showTileDebugInfo,
      this.paintBackground, this.paintNoDataTiles, this.mapZoom);
}

class VectorTileLayer extends StatefulWidget {
  final _LayerOptions options;
  final MapState mapState;
  final Stream<Null> stream;
  final TileSupplier tileSupplier;

  const VectorTileLayer(
      Key key, this.options, this.mapState, this.stream, this.tileSupplier)
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _VectorTileLayerState();
  }
}

class _VectorTileLayerState extends DisposableState<VectorTileLayer> {
  StreamSubscription<Null>? _subscription;
  late TileWidgets _tileWidgets;
  late final _ZoomScaler _zoomScaler;

  MapState get _mapState => widget.mapState;

  double get _zoom => widget.options.mapZoom();
  double get _clampedZoom => _zoom.roundToDouble();

  @override
  void initState() {
    super.initState();
    _zoomScaler = _ZoomScaler(_mapState.options.crs);
    _createTileWidgets();
    _subscription = widget.stream.listen((event) {
      _update();
    });
    _update();
  }

  @override
  void dispose() {
    super.dispose();
    _subscription?.cancel();
    _tileWidgets.dispose();
  }

  @override
  void didUpdateWidget(covariant VectorTileLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.options.theme.id != widget.options.theme.id) {
      setState(() {
        _createTileWidgets();
        _updateTiles();
      });
    }
  }

  void _createTileWidgets() {
    _tileWidgets = TileWidgets(
        (tileZoom) => _zoomScaler.zoomScale(tileZoom),
        () => _zoom,
        widget.options.theme,
        widget.tileSupplier,
        widget.options.renderMode,
        widget.options.paintBackground,
        widget.options.showTileDebugInfo);
    _tileWidgets.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    _tileWidgets.updateWidgets();

    final tiles = _tileWidgets.all.entries
        .where((entry) =>
            widget.options.paintNoDataTiles || entry.value.model.hasData)
        .toList()
      ..sort(_orderTileWidgets);
    if (tiles.isEmpty) {
      return Container();
    }
    _zoomScaler.updateMapZoomScale(_mapState.zoom);

    final tileWidgets = <Widget>[];
    var positioner = GridTilePositioner(
        tiles.first.key.z,
        TilePositioningState(
            _zoomScaler.zoomScale(tiles.first.key.z), _mapState, _zoom));
    tiles.forEach((tile) {
      if (tile.key.z != positioner.tileZoom) {
        positioner = GridTilePositioner(
            tile.key.z,
            TilePositioningState(
                _zoomScaler.zoomScale(tile.key.z), _mapState, _zoom));
      }
      tileWidgets.add(positioner.positionTile(tile.key, tile.value));
    });
    return Stack(children: tileWidgets);
  }

  void _update() {
    if (disposed) {
      return;
    }
    setState(() {
      _updateTiles();
    });
  }

  void _updateTiles() {
    final pixelBounds = _tiledPixelBounds();
    final tileRange = _pixelBoundsToTileRange(pixelBounds);
    final tiles = _expand(tileRange);
    _tileWidgets.update(tiles);
  }

  Bounds _tiledPixelBounds() {
    final zoom = _mapState.zoom;
    final scale = _mapState.getZoomScale(zoom, _clampedZoom);
    final centerPoint =
        _mapState.project(_mapState.center, _clampedZoom).floor();
    final halfSize = _mapState.size / (scale * 2);

    return Bounds(centerPoint - halfSize, centerPoint + halfSize);
  }

  Bounds _pixelBoundsToTileRange(Bounds bounds) => Bounds(
        bounds.min.unscaleBy(tileSize).floor(),
        bounds.max.unscaleBy(tileSize).ceil() - const CustomPoint(1, 1),
      );

  List<TileIdentity> _expand(Bounds range) {
    final zoom = _clampedZoom;
    final tiles = <TileIdentity>[];
    for (num x = range.min.x; x <= range.max.x; ++x) {
      for (num y = range.min.y; y <= range.max.y; ++y) {
        if (x.toInt() >= 0 && y.toInt() >= 0) {
          tiles.add(TileIdentity(zoom.toInt(), x.toInt(), y.toInt()));
        }
      }
    }
    return tiles;
  }
}

int _orderTileWidgets(
    MapEntry<TileIdentity, Widget> a, MapEntry<TileIdentity, Widget> b) {
  int i = a.key.z.compareTo(b.key.z);
  if (i == 0) {
    i = a.key.x.compareTo(b.key.x);
    if (i == 0) {
      i = a.key.y.compareTo(b.key.y);
    }
  }
  return i;
}

class _ZoomScaler {
  final _crsScaleByZoom = <double>[];
  var _mapZoomCrsScale = 1.0;
  final Crs _crs;

  _ZoomScaler(this._crs) {
    _crsScaleByZoom.add(1.0);
    for (int zoom = 1; zoom < 24; ++zoom) {
      _crsScaleByZoom.add(_crs.scale(zoom.toDouble()).toDouble());
    }
  }

  void updateMapZoomScale(double mapZoom) {
    _mapZoomCrsScale = _crs.scale(mapZoom).toDouble();
  }

  double zoomScale(int tileZoom) {
    var tileScale = _crsScaleByZoom[tileZoom];
    return _mapZoomCrsScale / tileScale;
  }
}
