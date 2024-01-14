import 'dart:async';
import 'dart:math';

import 'package:executor_lib/executor_lib.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart' hide TileLayer;

import '../cache/cache_storage_function.dart';
import '../cache/caches.dart';
import '../options.dart';
import '../raster/raster_tile_provider.dart';
import '../stream/caches_tile_provider.dart';
import '../stream/delay_provider.dart';
import '../stream/tile_processor.dart';
import '../stream/tile_supplier_raster.dart';
import '../stream/tileset_executor_preprocessor.dart';
import '../stream/tileset_ui_preprocessor.dart';
import '../stream/translating_tile_provider.dart';
import '../style/style.dart';
import '../tile_identity.dart';
import '../tile_offset.dart';
import '../tile_providers.dart';
import '../tile_viewport.dart';
import '../vector_tile_layer_mode.dart';
import 'constants.dart';
import 'debounce.dart';
import 'grid_tile_positioner.dart';
import 'tile/disposable_state.dart';
import 'tile_widgets.dart';

class VectorTileCompositeLayer extends StatefulWidget {
  final MapCamera mapCamera;
  final VectorTileLayerOptions options;

  const VectorTileCompositeLayer(this.options, this.mapCamera, {super.key});

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
  late RasterTileProvider _rasterTileProvider;
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
    final newState = widget.mapCamera.toMapState();
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
    if (options.layerMode == VectorTileLayerMode.raster) {
      final maxZoom = options.maximumZoom ?? 18;

      final tileProvider = _tileProvider ??
          createRasterTileProvider(
              theme,
              widget.options.sprites,
              _caches,
              _rasterTileProvider,
              _executor,
              options.tileOffset,
              options.tileDelay,
              options.concurrency);
      _tileProvider = tileProvider;
      return TileLayer(
          key: Key("${theme.id}_v${theme.version}_VectorTileLayer"),
          maxZoom: maxZoom,
          maxNativeZoom: maxZoom.ceil(),
          evictErrorTileStrategy: EvictErrorTileStrategy.notVisible,
          tileProvider: tileProvider);
    }
    final layers = <Widget>[];
    if (backgroundTheme != null) {
      final background = _VectorTileLayer(
          Key(
              "${backgroundTheme.id}_v${theme.version}_background_VectorTileLayer"),
          _LayerOptions(const TileProviders({}), backgroundTheme,
              caches: _caches,
              showTileDebugInfo: options.showTileDebugInfo,
              paintBackground: true,
              maxSubstitutionDifference: 0,
              paintNoDataTiles: true,
              tileOffset: widget.options.tileOffset,
              tileZoomSubstitutionOffset: 4,
              mapZoom: _zoom,
              rotation: _rotation),
          widget.mapCamera,
          _mapChanged.stream,
          _tileSupplier,
          RasterTileProvider(
              providers: const TileProviders({}),
              cache: _caches.imageLoadingCache));
      layers.add(background);
    }
    layers.add(_VectorTileLayer(
        Key("${theme.id}_v${theme.version}_VectorTileLayer"),
        _LayerOptions(options.tileProviders, theme,
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
            mapZoom: _zoom,
            rotation: _rotation),
        widget.mapCamera,
        _mapChanged.stream,
        _tileSupplier,
        _rasterTileProvider));
    return MobileLayerTransformer(child: Stack(children: layers));
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
        maxTextCacheSize: widget.options.textCacheMaxSize,
        cacheStorage: widget.options.cacheFolder ?? cacheStorageResolver);
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
    _rasterTileProvider = RasterTileProvider(
        providers: widget.options.tileProviders,
        cache: _caches.imageLoadingCache);
  }

  void _printCacheStats() {
    // ignore: avoid_print
    print('Cache stats:\n${_caches.stats()}');
  }

  double _zoom() => max(
      1,
      (widget.mapCamera.zoom + widget.options.tileOffset.zoomOffset)
          .floorToDouble());
  double _rotation() => widget.mapCamera.rotationRad;
}

class _LayerOptions {
  final TileProviders providers;
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
  final double Function() rotation;
  final Caches caches;
  _LayerOptions(this.providers, this.theme,
      {this.symbolTheme,
      this.sprites,
      required this.caches,
      required this.showTileDebugInfo,
      required this.paintBackground,
      required this.paintNoDataTiles,
      required this.maxSubstitutionDifference,
      required this.tileOffset,
      required this.tileZoomSubstitutionOffset,
      required this.mapZoom,
      required this.rotation});
}

class _VectorTileLayer extends StatefulWidget {
  final _LayerOptions options;
  final MapCamera mapState;
  final Stream<void> stream;
  final TranslatingTileProvider tileProvider;
  final RasterTileProvider rasterTileProvider;

  const _VectorTileLayer(Key key, this.options, this.mapState, this.stream,
      this.tileProvider, this.rasterTileProvider)
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

  MapCamera get _mapCamera => widget.mapState;

  double get _zoom => widget.options.mapZoom();
  double get _detailZoom =>
      widget.options.mapZoom() - widget.options.tileOffset.zoomOffset;
  double get _clampedZoom => max(1.0, _zoom.floorToDouble());
  double get _rotation => widget.options.rotation();

  @override
  void initState() {
    super.initState();
    _zoomScaler = _ZoomScaler(_mapCamera.crs);
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
        () => _rotation,
        widget.options.theme,
        widget.options.symbolTheme,
        widget.options.sprites,
        widget.options.caches.atlasImageCache?.retrieve,
        widget.tileProvider,
        widget.rasterTileProvider,
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
    _zoomScaler.updateMapZoomScale(_mapCamera.zoom);

    final tileWidgets = <Widget>[];
    var positioner = GridTilePositioner(
        tiles.first.key.z,
        TilePositioningState(
            _zoomScaler.zoomScale(tiles.first.key.z), _mapCamera, _zoom));
    for (final tile in tiles) {
      if (tile.key.z != positioner.tileZoom) {
        positioner = GridTilePositioner(
            tile.key.z,
            TilePositioningState(
                _zoomScaler.zoomScale(tile.key.z), _mapCamera, _zoom));
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
    final zoom = _mapCamera.zoom;
    final scale = _mapCamera.getZoomScale(zoom, _clampedZoom);
    final centerPoint = _mapCamera.project(_mapCamera.center, _clampedZoom);
    final halfSize = _mapCamera.size / (scale * 2);

    return Bounds(centerPoint - halfSize, centerPoint + halfSize);
  }

  TileViewport _pixelBoundsToTileViewport(Bounds pixelBounds) {
    final zoom = _clampedZoom.toInt();
    final a = pixelBounds.min.unscaleBy(tileSize).floor();
    final b = pixelBounds.max.unscaleBy(tileSize).ceil() - const Point(1, 1);
    final topLeft = Point<int>(a.x.toInt(), a.y.toInt());
    final bottomRight = Point<int>(b.x.toInt(), b.y.toInt());
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
  final Point pixelOrigin;
  final LatLng center;
  final Point<double> size;
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

extension _MapStateExtension on MapCamera {
  _MapState toMapState() => _MapState(
      zoom, rotation, pixelOrigin, center, size, visibleBounds, pixelBounds);
}
