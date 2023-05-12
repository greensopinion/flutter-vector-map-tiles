import 'dart:async';
import 'dart:math';

import 'package:executor_lib/executor_lib.dart';
import 'package:flutter/material.dart' as material show Theme;
import 'package:flutter/widgets.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart' hide TileLayer;

import '../cache/caches.dart';
import '../options.dart';
import '../raster/raster_tile_provider.dart';
import '../stream/caches_tile_provider.dart';
import '../stream/delay_provider.dart';
import '../stream/tile_processor.dart';
import '../stream/tileset_executor_preprocessor.dart';
import '../stream/tileset_ui_preprocessor.dart';
import '../stream/translating_tile_provider.dart';
import '../style/style.dart';
import '../tile_identity.dart';
import '../tile_offset.dart';
import '../tile_viewport.dart';
import '../vector_tile_layer_mode.dart';
import 'constants.dart';
import 'debounce.dart';
import 'grid_tile_positioner.dart';
import 'tile/disposable_state.dart';
import 'tile_widgets.dart';

class VectorTileCompositeLayer extends StatefulWidget {
  final FlutterMapState mapState;
  final VectorTileLayerOptions options;

  const VectorTileCompositeLayer(this.options, this.mapState, {super.key});

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
  final _mapChanged = StreamController.broadcast();
  _MapState? _previousState;
  StreamSubscription<void>? _subscription;
  Theme? _theme;
  Theme? _symbolTheme;
  TileProvider? _tileProvider;

  Theme get theme =>
      _theme ??
      (_theme = widget.options.layerMode == VectorTileLayerMode.raster
          ? widget.options.theme
          : widget.options.theme.copyWith(
              types: ThemeLayerType.values
                  .where((it) => it != ThemeLayerType.symbol)
                  .toSet()));
  Theme get symbolTheme =>
      _symbolTheme ??
      (_symbolTheme =
          widget.options.theme.copyWith(types: {ThemeLayerType.symbol}));

  @override
  void initState() {
    super.initState();
    _executor = newExecutor(concurrency: widget.options.concurrency);
    _createCaches();
    Future.delayed(const Duration(seconds: 3), () {
      _caches.applyConstraints();
    });
    if (widget.options.logCacheStats) {
      _subscription = _mapChanged.stream.listen((event) {
        _cacheStats.update();
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    _subscription?.cancel();
    _mapChanged.close();
    _caches.dispose();
    _tileProvider?.dispose();
    _tileProvider = null;
    _executor.dispose();
  }

  @override
  void didHaveMemoryPressure() {
    _caches.didHaveMemoryPressure();
  }

  @override
  void didUpdateWidget(covariant VectorTileCompositeLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newState = widget.mapState.toMapState();
    final previousState = _previousState;
    _previousState = newState;
    if (widget.options.hasRenderDifferences(oldWidget.options)) {
      setState(() {
        _theme = null;
        _symbolTheme = null;
        _caches.dispose();
        _tileProvider?.dispose();
        _tileProvider = null;
        _createCaches();
      });
    } else if (newState != previousState) {
      _mapChanged.add(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = widget.options;
    final backgroundTheme = options.backgroundTheme;
    final layers = <Widget>[];
    if (options.layerMode == VectorTileLayerMode.raster) {
      final maxZoom = options.maximumZoom ?? 18;

      final tileProvider = _tileProvider ??
          createRasterTileProvider(
              theme,
              widget.options.sprites,
              _caches,
              _executor,
              options.tileOffset,
              options.tileDelay,
              options.concurrency);
      _tileProvider = tileProvider;
      final hasBackground = theme.layers
          .where((layer) => layer.type == ThemeLayerType.background)
          .isNotEmpty;
      layers.add(TileLayer(
          key: Key("${theme.id}_v${theme.version}_VectorTileLayer"),
          maxZoom: maxZoom,
          maxNativeZoom: maxZoom.ceil(),
          evictErrorTileStrategy: EvictErrorTileStrategy.notVisible,
          backgroundColor: hasBackground
              ? material.Theme.of(context).canvasColor
              : const Color.fromARGB(0, 0, 0, 0),
          tileProvider: tileProvider));
    }
    if (options.layerMode == VectorTileLayerMode.vector) {
      layers.add(_VectorTileLayer(
          Key("${theme.id}_v${theme.version}_VectorTileLayer"),
          _LayerOptions(theme,
              caches: _caches,
              symbolTheme: symbolTheme,
              sprites: options.sprites,
              showTileDebugInfo: options.showTileDebugInfo,
              paintBackground: backgroundTheme == null,
              maxSubstitutionDifference:
                  options.maximumTileSubstitutionDifference,
              paintNoDataTiles: false,
              tileOffset: widget.options.tileOffset,
              tileZoomSubstitutionOffset: 0,
              mapZoom: _zoom),
          widget.mapState,
          _mapChanged.stream,
          _tileSupplier));
      if (backgroundTheme != null) {
        final background = _VectorTileLayer(
            Key(
                "${backgroundTheme.id}_v${theme.version}_background_VectorTileLayer"),
            _LayerOptions(backgroundTheme,
                caches: _caches,
                showTileDebugInfo: options.showTileDebugInfo,
                paintBackground: true,
                maxSubstitutionDifference: 0,
                paintNoDataTiles: true,
                tileOffset: widget.options.tileOffset,
                tileZoomSubstitutionOffset: 4,
                mapZoom: _zoom),
            widget.mapState,
            _mapChanged.stream,
            _tileSupplier);
        layers.insert(0, background);
      }
    }
    return Stack(children: layers);
  }

  void _createCaches() {
    _caches = Caches(
        executor: _executor,
        providers: widget.options.tileProviders,
        theme: widget.options.theme,
        sprites: widget.options.sprites,
        ttl: widget.options.fileCacheTtl,
        memoryTileCacheMaxSize: widget.options.memoryTileCacheMaxSize,
        memoryTileDataCacheMaxSize: widget.options.memoryTileDataCacheMaxSize,
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

  double _zoom() => max(
      1,
      (widget.mapState.zoom + widget.options.tileOffset.zoomOffset)
          .floorToDouble());
}

class _LayerOptions {
  final Theme theme;
  final Theme? symbolTheme;
  final SpriteStyle? sprites;
  final bool showTileDebugInfo;
  final bool paintBackground;
  final int maxSubstitutionDifference;
  final bool paintNoDataTiles;
  final TileOffset tileOffset;
  final int tileZoomSubstitutionOffset;
  final double Function() mapZoom;
  final Caches caches;
  _LayerOptions(this.theme,
      {this.symbolTheme,
      this.sprites,
      required this.caches,
      required this.showTileDebugInfo,
      required this.paintBackground,
      required this.paintNoDataTiles,
      required this.maxSubstitutionDifference,
      required this.tileOffset,
      required this.tileZoomSubstitutionOffset,
      required this.mapZoom});
}

class _VectorTileLayer extends StatefulWidget {
  final _LayerOptions options;
  final FlutterMapState mapState;
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

  FlutterMapState get _mapState => widget.mapState;

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
        widget.options.sprites,
        widget.options.caches.atlasImageCache?.retrieve,
        widget.tileProvider,
        widget.options.caches.textCache,
        widget.options.maxSubstitutionDifference,
        widget.options.tileZoomSubstitutionOffset,
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
        .toList(growable: false)
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
    final centerPoint = _mapState.project(_mapState.center, _clampedZoom);
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
          final tile = TileIdentity(viewport.zoom, x, y);
          if (tile.isValid()) {
            tiles.add(tile);
          }
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

class _MapState {
  final double zoom;
  final double rotation;
  final CustomPoint pixelOrigin;
  final LatLng center;
  final CustomPoint<double> size;
  final LatLngBounds bounds;
  final Bounds pixelBounds;

  _MapState(this.zoom, this.rotation, this.pixelOrigin, this.center, this.size,
      this.bounds, this.pixelBounds);

  @override
  operator ==(other) =>
      other is _MapState &&
      zoom == other.zoom &&
      pixelOrigin == other.pixelOrigin &&
      center == other.center &&
      size == other.size &&
      bounds == other.bounds &&
      pixelBounds.min == other.pixelBounds.min &&
      pixelBounds.max == other.pixelBounds.max &&
      rotation == other.rotation;

  @override
  int get hashCode => Object.hash(zoom, center, size);
}

extension _MapStateExtension on FlutterMapState {
  _MapState toMapState() =>
      _MapState(zoom, rotation, pixelOrigin, center, size, bounds, pixelBounds);
}
