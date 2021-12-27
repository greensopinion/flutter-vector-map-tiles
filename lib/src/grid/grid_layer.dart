import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../cache/caches.dart';
import '../options.dart';
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
  late Caches _caches;
  late final _cacheStats = ScheduledDebounce(_printCacheStats,
      delay: Duration(seconds: 1),
      jitter: Duration(milliseconds: 0),
      maxAge: Duration(seconds: 3));
  StreamSubscription<Null>? _subscription;

  @override
  void initState() {
    super.initState();
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
              () => widget.mapState.zoom),
          widget.mapState,
          widget.stream,
          _caches)
    ];
    if (backgroundTheme != null) {
      final background = VectorTileLayer(
          Key("${backgroundTheme.id}_background_VectorTileLayer"),
          _LayerOptions(backgroundTheme, RenderMode.vector,
              options.showTileDebugInfo, true, _backgroundZoom),
          widget.mapState,
          widget.stream,
          _caches);
      layers.insert(0, background);
    }
    return Stack(children: layers);
  }

  void _createCaches() {
    _caches = Caches(
        providers: widget.options.tileProviders,
        pipeline: RendererPipeline(widget.options.theme,
            scale: widget.options.rasterImageScale),
        ttl: widget.options.fileCacheTtl,
        maxImagesInMemory: widget.options.maxImagesInMemory,
        maxSizeInBytes: widget.options.fileCacheMaximumSizeInBytes);
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
  final double Function() mapZoom;

  _LayerOptions(this.theme, this.renderMode, this.showTileDebugInfo,
      this.paintBackground, this.mapZoom);
}

class VectorTileLayer extends StatefulWidget {
  final _LayerOptions options;
  final MapState mapState;
  final Stream<Null> stream;
  final Caches caches;

  const VectorTileLayer(
      Key key, this.options, this.mapState, this.stream, this.caches)
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _VectorTileLayerState();
  }
}

class _VectorTileLayerState extends DisposableState<VectorTileLayer> {
  StreamSubscription<Null>? _subscription;
  late TileWidgets _tileWidgets;

  MapState get _mapState => widget.mapState;
  double get _zoom => widget.options.mapZoom();
  double get _clampedZoom => _zoom.roundToDouble();
  double _paintZoomScale = 1.0;

  @override
  void initState() {
    super.initState();

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
        () => _paintZoomScale,
        () => _zoom,
        widget.options.theme,
        widget.caches,
        widget.options.renderMode,
        widget.options.paintBackground,
        widget.options.showTileDebugInfo);
  }

  @override
  Widget build(BuildContext context) {
    if (_tileWidgets.all.isEmpty) {
      return Container();
    }
    _updatePaintZoomScale();
    final positioner = GridTilePositioner(
        TilePositioningState(_paintZoomScale, _mapState, _zoom));
    final tileWidgets = _tileWidgets.all.entries
        .map((entry) => positioner.positionTile(entry.key, entry.value))
        .toList();
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

  double _zoomScale(double mapZoom, double tileZoom) {
    final crs = _mapState.options.crs;
    return crs.scale(mapZoom) / crs.scale(tileZoom);
  }

  void _updatePaintZoomScale() {
    final tileZoom = _tileWidgets.all.keys.first.z;
    _paintZoomScale = _zoomScale(widget.mapState.zoom, tileZoom.toDouble());
  }
}
