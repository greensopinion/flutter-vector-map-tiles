import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/plugin_api.dart';
import '../stream/tile_processor.dart';
import '../stream/tileset_ui_preprocessor.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../cache/caches.dart';
import '../executor/executor.dart';
import '../options.dart';
import '../stream/caches_tile_provider.dart';
import '../stream/delay_provider.dart';
import '../stream/tileset_executor_preprocessor.dart';
import '../stream/translating_tile_provider.dart';
import '../tile_identity.dart';
import '../tile_viewport.dart';
import 'constants.dart';
import 'debounce.dart';
import 'tile/disposable_state.dart';
import 'grid_tile_positioner.dart';
import 'tile_widgets.dart';

class VectorTileCompositeLayer extends StatefulWidget {
  final VectorTileLayerOptions options;
  final MapState mapState;

  const VectorTileCompositeLayer({super.key, required this.options, required this.mapState});

  @override
  State<StatefulWidget> createState() {
    return _VectorTileCompositeLayerState();
  }
}

class _VectorTileCompositeLayerState extends State<VectorTileCompositeLayer>
    with WidgetsBindingObserver {
  late Executor _executor;
  late Caches _caches;
  late TranslatingTileProvider _tileSupplier;
  late final _cacheStats = ScheduledDebounce(_printCacheStats,
      delay: const Duration(seconds: 1),
      jitter: const Duration(milliseconds: 0),
      maxAge: const Duration(seconds: 3));
  StreamSubscription<void>? _subscription;

  @override
  void initState() {
    super.initState();
    _executor = newExecutor(concurrency: widget.options.concurrency);
    _createCaches();
    Future.delayed(const Duration(seconds: 3), () {
      _caches.applyConstraints();
    });
    if (widget.options.logCacheStats) {
      _subscription = widget.mapState.onMoved.listen((event) {
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
    final symbolTheme = options.theme.copyWith(types: {ThemeLayerType.symbol});
    final theme = options.theme.copyWith(types: {
      ThemeLayerType.background,
      ThemeLayerType.fill,
      ThemeLayerType.fillExtrusion,
      ThemeLayerType.line
    });
    final layers = <Widget>[
      _VectorTileLayer(
          Key("${theme.id}_VectorTileLayer"),
          _LayerOptions(theme,
              caches: _caches,
              symbolTheme: symbolTheme,
              showTileDebugInfo: options.showTileDebugInfo,
              paintBackground: backgroundTheme == null,
              substituteTilesWhileLoading: true,
              paintNoDataTiles: false,
              tileOffset: widget.options.tileOffset,
              mapZoom: () =>
                  widget.mapState.zoom + widget.options.tileOffset.zoomOffset),
          widget.mapState,
          widget.mapState.onMoved,
          _tileSupplier)
    ];
    if (backgroundTheme != null) {
      final background = _VectorTileLayer(
          Key("${backgroundTheme.id}_background_VectorTileLayer"),
          _LayerOptions(backgroundTheme,
              caches: _caches,
              showTileDebugInfo: options.showTileDebugInfo,
              paintBackground: true,
              substituteTilesWhileLoading: false,
              paintNoDataTiles: true,
              tileOffset: widget.options.tileOffset,
              mapZoom: _backgroundZoom),
          widget.mapState,
          widget.mapState.onMoved,
          _tileSupplier);
      layers.insert(0, background);
    }
    return Stack(children: layers);
  }

  void _createCaches() {
    _caches = Caches(
        executor: _executor,
        providers: widget.options.tileProviders,
        theme: widget.options.theme,
        ttl: widget.options.fileCacheTtl,
        memoryTileCacheMaxSize: widget.options.memoryTileCacheMaxSize,
        maxSizeInBytes: widget.options.fileCacheMaximumSizeInBytes,
        maxTextCacheSize: widget.options.textCacheMaxSize);
    _tileSupplier = TranslatingTileProvider(DelayProvider(
            CachesTileProvider(
                _caches,
                TileProcessor(_executor),
                TilesetExecutorPreprocessor(
                    TilesetPreprocessor(widget.options.theme), _executor),
                TilesetUiPreprocessor(TilesetPreprocessor(widget.options.theme,
                    initializeGeometry: true))),
            widget.options.tileDelay)
        .orDelegate());
  }

  void _printCacheStats() {
    // ignore: avoid_print
    print('Cache stats:\n${_caches.stats()}');
  }

  double _backgroundZoom() {
    return max(
        1,
        (widget.mapState.zoom - 1 + widget.options.tileOffset.zoomOffset)
            .floorToDouble());
  }
}

class _LayerOptions {
  final Theme theme;
  final Theme? symbolTheme;
  final bool showTileDebugInfo;
  final bool paintBackground;
  final bool substituteTilesWhileLoading;
  final bool paintNoDataTiles;
  final TileOffset tileOffset;
  final double Function() mapZoom;
  final Caches caches;
  _LayerOptions(this.theme,
      {this.symbolTheme,
      required this.caches,
      required this.showTileDebugInfo,
      required this.paintBackground,
      required this.paintNoDataTiles,
      required this.substituteTilesWhileLoading,
      required this.tileOffset,
      required this.mapZoom});
}

class _VectorTileLayer extends StatefulWidget {
  final _LayerOptions options;
  final MapState mapState;
  final Stream<void> stream;
  final TranslatingTileProvider tileProvider;

  const _VectorTileLayer(
      Key key, this.options, this.mapState, this.stream, this.tileProvider)
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _VectorTileLayerState();
  }
}

class _VectorTileLayerState extends DisposableState<_VectorTileLayer> {
  StreamSubscription<void>? _subscription;
  late TileWidgets _tileWidgets;
  late final _ZoomScaler _zoomScaler;

  MapState get _mapState => widget.mapState;

  double get _zoom => widget.options.mapZoom();
  double get _detailZoom =>
      widget.options.mapZoom() - widget.options.tileOffset.zoomOffset;
  double get _clampedZoom => max(1.0, _zoom.floorToDouble());

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
  void didUpdateWidget(covariant _VectorTileLayer oldWidget) {
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
        () => _detailZoom,
        widget.options.theme,
        widget.options.symbolTheme,
        widget.tileProvider,
        widget.options.caches.textCache,
        widget.options.substituteTilesWhileLoading,
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
    for (final tile in tiles) {
      if (tile.key.z != positioner.tileZoom) {
        positioner = GridTilePositioner(
            tile.key.z,
            TilePositioningState(
                _zoomScaler.zoomScale(tile.key.z), _mapState, _zoom));
      }
      tileWidgets.add(positioner.positionTile(tile.key, tile.value));
    }
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
    final tileViewport = _pixelBoundsToTileViewport(pixelBounds);
    final tiles = _expand(tileViewport);
    _tileWidgets.update(tileViewport, tiles);
  }

  Bounds _tiledPixelBounds() {
    final zoom = _mapState.zoom;
    final scale = _mapState.getZoomScale(zoom, _clampedZoom);
    final centerPoint =
        _mapState.project(_mapState.center, _clampedZoom).floor();
    final halfSize = _mapState.size / (scale * 2);

    return Bounds(centerPoint - halfSize, centerPoint + halfSize);
  }

  TileViewport _pixelBoundsToTileViewport(Bounds pixelBounds) {
    final zoom = _clampedZoom.toInt();
    final a = pixelBounds.min.unscaleBy(tileSize).floor();
    final b =
        pixelBounds.max.unscaleBy(tileSize).ceil() - const CustomPoint(1, 1);
    final topLeft = CustomPoint<int>(a.x.toInt(), a.y.toInt());
    final bottomRight = CustomPoint<int>(b.x.toInt(), b.y.toInt());
    return TileViewport(zoom, Bounds<int>(topLeft, bottomRight));
  }

  List<TileIdentity> _expand(TileViewport viewport) {
    final bounds = viewport.bounds;
    final tiles = <TileIdentity>[];
    for (int x = bounds.min.x; x <= bounds.max.x; ++x) {
      for (int y = bounds.min.y; y <= bounds.max.y; ++y) {
        if (x >= 0 && y >= 0) {
          tiles.add(TileIdentity(viewport.zoom, x, y));
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
