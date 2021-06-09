import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:vector_map_tiles/src/renderer_pipeline.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';
import 'cache/caches.dart';
import 'disposable_state.dart';
import 'tile_identity.dart';
import 'vector_tile_provider.dart';
import 'tile_widgets.dart';

enum RenderMode {
  /// tiles are rendered using vectors only
  vector,

  /// tiles are rendered using vectors when idle, and raster images when
  /// zooming. Can improve the frame rate and reduce jank.
  mixed
}

class VectorTileLayerOptions extends LayerOptions {
  /// provides vector tiles
  final VectorTileProvider tileProvider;

  /// the theme used to render tiles
  final Theme theme;

  /// determines how tiles are rendered to the canvas.
  /// `vector` - exclusively uses vector rendering. Produces the sharpest map
  /// images.
  /// `mixed` - uses raster tiles while zooming and renders using vectors when
  /// idle. Makes for smooth animations while the user interacts with the map
  /// and reduces CPU overhead.
  final RenderMode renderMode;

  /// the maximum number of rendered tiles to cache. Increasing this number improves
  /// the transition between tiles when zooming and panning at the expense of memory.
  /// If memory pressure is experienced, this the provided number is reduced automatically
  /// however setting this value too high can cause performance problems due to memory
  /// pressure.
  final int maxCachedTiles;

  /// the scale of raster images when using `mixed` [renderMode].
  /// best quality corresponds to the device pixel ratio, at the expense of
  /// memory. Set to 1.0 to have lowest memory usage.
  final double rasterImageScale;

  /// the time to live of items in the file cache
  /// consider the terms of your tile provider service
  /// and the desired freshness of map data when setting this value
  final Duration fileCacheTtl;
  static const DEFAULT_CACHE_TTL = Duration(days: 30);

  final fileCacheMaximumSizeInBytes;
  static const DEFAULT_CACHE_MAX_SIZE = 50 * 1024 * 1024;

  VectorTileLayerOptions(
      {required this.tileProvider,
      required this.theme,
      this.maxCachedTiles = 20,
      this.rasterImageScale = 3.0,
      this.renderMode = RenderMode.vector,
      this.fileCacheTtl = DEFAULT_CACHE_TTL,
      this.fileCacheMaximumSizeInBytes = DEFAULT_CACHE_MAX_SIZE}) {
    assert(rasterImageScale >= 1.0 && rasterImageScale <= 5.0);
    assert(maxCachedTiles >= 1 && maxCachedTiles <= 60);
  }
}

class VectorTileLayer extends StatefulWidget {
  final VectorTileLayerOptions options;
  final MapState mapState;
  final Stream<Null> stream;

  const VectorTileLayer(this.options, this.mapState, this.stream);

  @override
  State<StatefulWidget> createState() {
    return _VectorTileLayerState();
  }
}

class _VectorTileLayerState extends DisposableState<VectorTileLayer>
    with WidgetsBindingObserver {
  StreamSubscription<Null>? _subscription;
  late final TileWidgets _tileWidgets;
  late final Caches _caches;

  MapState get _mapState => widget.mapState;
  double get _clampedZoom => _mapState.zoom.roundToDouble();
  double _paintZoomScale = 1.0;

  @override
  void initState() {
    super.initState();
    _caches = Caches(
        provider: widget.options.tileProvider,
        pipeline: RendererPipeline(widget.options.theme,
            scale: widget.options.rasterImageScale),
        ttl: widget.options.fileCacheTtl,
        maxSizeInBytes: widget.options.fileCacheMaximumSizeInBytes);
    Future.delayed(Duration(seconds: 3), () {
      _caches.applyConstraints();
    });
    _tileWidgets = TileWidgets(
        widget.options.tileProvider,
        () => _paintZoomScale,
        () => _mapState.zoom,
        widget.options.theme,
        _caches);
    _subscription = widget.stream.listen((event) {
      _update();
    });
    _update();
  }

  @override
  void dispose() {
    super.dispose();
    _caches.dispose();
    _subscription?.cancel();
  }

  @override
  void didHaveMemoryPressure() {
    _caches.didHaveMemoryPressure();
  }

  @override
  Widget build(BuildContext context) {
    if (_tileWidgets.all.isEmpty) {
      return Container();
    }
    _updatePaintZoomScale();
    final tileWidgets = _tileWidgets.all.entries
        .map((entry) => _positionTile(entry.key, entry.value))
        .toList();
    return Stack(children: tileWidgets);
  }

  void _update() {
    if (disposed) {
      return;
    }
    final center = _mapState.center;
    final pixelBounds = _tiledPixelBounds(center);
    final tileRange = _pixelBoundsToTileRange(pixelBounds);
    final tiles = _expand(tileRange);
    _tileWidgets.update(tiles);
    setState(() {});
  }

  Bounds _tiledPixelBounds(LatLng center) {
    var scale = _mapState.getZoomScale(_mapState.zoom, _clampedZoom);
    var centerPoint = _mapState.project(center, _clampedZoom).floor();
    var halfSize = _mapState.size / (scale * 2);

    return Bounds(centerPoint - halfSize, centerPoint + halfSize);
  }

  Bounds _pixelBoundsToTileRange(Bounds bounds) => Bounds(
        bounds.min.unscaleBy(_tileSize).floor(),
        bounds.max.unscaleBy(_tileSize).ceil() - const CustomPoint(1, 1),
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

  Widget _positionTile(TileIdentity tile, Widget tileWidget) {
    final zoomScale = _paintZoomScale;
    final pixelOrigin =
        _mapState.getNewPixelOrigin(_mapState.center, _mapState.zoom).round();
    final origin =
        _mapState.project(_mapState.unproject(pixelOrigin), _mapState.zoom);
    final translate = origin.multiplyBy(zoomScale) - pixelOrigin;
    final tilePosition =
        (tile.scaleBy(_tileSize) - origin).multiplyBy(zoomScale) + translate;
    return Positioned(
        key: Key('PositionedGridTile_${tile.z}_${tile.x}_${tile.y}'),
        top: tilePosition.y.toDouble(),
        left: tilePosition.x.toDouble(),
        width: (_tileSize.x * zoomScale),
        height: (_tileSize.y * zoomScale),
        child: tileWidget);
  }

  double _zoomScale(double mapZoom, double tileZoom) {
    final crs = _mapState.options.crs;
    return crs.scale(mapZoom) / crs.scale(tileZoom);
  }

  void _updatePaintZoomScale() {
    final tileZoom = _tileWidgets.all.keys.first.z;
    _paintZoomScale = _zoomScale(_mapState.zoom, tileZoom.toDouble());
  }
}

final _tileSize = CustomPoint(256, 256);
