import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:executor_lib/executor_lib.dart';
import 'package:flutter/widgets.dart' hide Image;
import 'package:flutter_map/flutter_map.dart' hide TileProvider;
import 'package:vector_tile_renderer/vector_tile_renderer.dart' hide TileLayer;

import '../../vector_map_tiles.dart';
import '../extensions.dart';
import '../grid/slippy_map_translator.dart';
import '../grid/tile_zoom.dart';
import '../rendering/tile_renderer.dart';
import '../stream/tile_supplier.dart';
import '../stream/tile_supplier_raster.dart';
import 'storage_image_cache.dart';

class TileLoader {
  final Theme _theme;
  late final Set<String> _themeSources;
  late String _sourcesKey;
  final SpriteStyle? _sprites;
  final Future<Image> Function()? _spriteAtlas;
  final TileProvider _provider;
  final RasterTileProvider _rasterTileProvider;
  final StorageImageCache _imageCache;
  final TileOffset _tileOffset;
  final int _concurrency;
  final _scale = 2.0;
  late final ConcurrencyExecutor _jobQueue;

  TileLoader(
      this._theme,
      this._sprites,
      this._spriteAtlas,
      this._provider,
      this._rasterTileProvider,
      this._tileOffset,
      this._imageCache,
      this._concurrency) {
    _themeSources = _theme.tileSources;
    _sourcesKey = _theme.tileSources.toList().sorted().join(',');
    _jobQueue = ConcurrencyExecutor(
        delegate: ImmediateExecutor(),
        concurrencyLimit: _concurrency * 2,
        maxQueueSize: _maxOutstandingJobs);
  }

  Future<ImageInfo> loadTile(TileCoordinates coords, TileLayer options,
      bool Function() cancelled) async {
    final requestedTile =
        TileIdentity(coords.z.toInt(), coords.x.toInt(), coords.y.toInt());
    var requestZoom = requestedTile.z;
    if (_tileOffset.zoomOffset < 0) {
      requestZoom = max(
          1, min(requestZoom + _tileOffset.zoomOffset, _provider.maximumZoom));
    }
    final cached = await _imageCache.retrieve(requestedTile);
    if (cached != null) {
      return ImageInfo(image: cached, scale: _scale);
    }
    final job =
        _TileJob(requestedTile, requestZoom, options.tileSize, cancelled);
    return _jobQueue.submit(Job<_TileJob, ImageInfo>(
        'render $requestedTile', _renderJob, job,
        deduplicationKey: 'render $requestedTile ${_theme.id}/$_sourcesKey'));
  }

  Future<ImageInfo> _renderJob(job) => _renderTile(
      job.requestedTile, job.requestZoom, job.tileSize, job.cancelled);

  Future<ImageInfo> _renderTile(TileIdentity requestedTile, int requestZoom,
      double tileSize, bool Function() cancelled) async {
    if (cancelled()) {
      throw CancellationException();
    }
    final tileRequest = TileRequest(
        tileId: requestedTile,
        tileSources: _themeSources,
        zoom: requestedTile.z.toDouble(),
        zoomDetail: requestedTile.z.toDouble(),
        cancelled: cancelled);
    final spriteAtlas = await _spriteAtlas?.call();
    final tileResponseFuture = _provider.provide(tileRequest);
    final rasterTile = await _rasterTileProvider
        .retrieve(requestedTile.normalize(), skipMissing: true);
    try {
      final tileResponse = await tileResponseFuture;
      final tileset = tileResponse.tileset;
      if (tileset == null) {
        throw 'No tile: $requestedTile';
      }
      final translator = SlippyMapTranslator(_provider.maximumZoom);
      final translation = translator.specificZoomTranslation(requestedTile,
          zoom: tileResponse.identity.z);

      final renderer = TileRenderer(
          theme: _theme,
          textPainterProvider: const DefaultTextPainterProvider(),
          tileState: TileState(
              zoom: requestedTile.z.toDouble(),
              zoomDetail: requestedTile.z.toDouble(),
              zoomScale: 0.0,
              rotation: 0.0),
          translation: translation,
          tileset: tileset,
          rasterTileset: rasterTile,
          spriteImage: spriteAtlas,
          sprites: _sprites);

      final size = Size.square(tileSize * _scale);
      final rect = Offset.zero & size;
      if (cancelled()) {
        throw CancellationException();
      }
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder, rect);
      canvas.scale(_scale);
      renderer.render(canvas, size / _scale);

      final picture = recorder.endRecording();
      final image =
          await picture.toImage(size.width.toInt(), size.height.toInt());
      await _cache(translation.original, image);
      return ImageInfo(image: image, scale: _scale);
    } finally {
      rasterTile.dispose();
    }
  }

  Future<void> _cache(TileIdentity tile, Image image) async {
    Image cloned = image.clone();
    try {
      await _imageCache.put(tile, cloned);
    } catch (_) {
      // nothing to do
    } finally {
      cloned.dispose();
    }
  }
}

class _TileJob {
  final TileIdentity requestedTile;
  final int requestZoom;
  final double tileSize;
  final bool Function() cancelled;

  _TileJob(this.requestedTile, this.requestZoom, this.tileSize, this.cancelled);
}

int _maxOutstandingJobs = 100;
