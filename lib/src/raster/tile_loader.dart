import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:executor_lib/executor_lib.dart';
import 'package:flutter/widgets.dart' hide Image;
import 'package:flutter_map/flutter_map.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart' hide TileLayer;

import '../../vector_map_tiles.dart';
import '../grid/grid_tile_positioner.dart';
import '../grid/slippy_map_translator.dart';
import '../stream/tile_supplier.dart';
import '../stream/tile_supplier_raster.dart';
import '../stream/translated_tile_request.dart';
import '../stream/translating_tile_provider.dart';
import 'storage_image_cache.dart';

class TileLoader {
  final Theme _theme;
  final SpriteStyle? _sprites;
  final Future<Image> Function()? _spriteAtlas;
  final TranslatingTileProvider _provider;
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
        deduplicationKey: 'render $requestedTile'));
  }

  Future<ImageInfo> _renderJob(job) => _renderTile(
      job.requestedTile, job.requestZoom, job.tileSize, job.cancelled);

  Future<ImageInfo> _renderTile(TileIdentity requestedTile, int requestZoom,
      double tileSize, bool Function() cancelled) async {
    if (cancelled()) {
      throw CancellationException();
    }
    final translator = SlippyMapTranslator(_provider.maximumZoom);
    var translation = translator.translate(requestedTile);
    final originalRequest = TileRequest(
        tileId: requestedTile,
        zoom: requestedTile.z.toDouble(),
        zoomDetail: requestedTile.z.toDouble(),
        cancelled: cancelled);
    final translatedRequest =
        createTranslatedRequest(originalRequest, maximumZoom: requestZoom);

    final spriteAtlas = await _spriteAtlas?.call();
    final tileResponseFuture = _provider.provide(translatedRequest);
    final rasterTile =
        await _rasterTileProvider.retrieve(requestedTile.normalize());
    try {
      final tileResponse = await tileResponseFuture;
      final tileset = tileResponse.tileset;
      if (tileset == null) {
        throw 'No tile: $requestedTile';
      }
      if (tileResponse.identity.z != translation.original.z) {
        translation = translator.specificZoomTranslation(requestedTile,
            zoom: tileResponse.identity.z);
      }

      final size = tileSize * _scale;
      final tileSizer = GridTileSizer(translation, _scale, Size.square(size));

      final rect = Rect.fromLTRB(0, 0, size, size);

      if (cancelled()) {
        throw CancellationException();
      }

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder, rect);
      canvas.clipRect(rect);
      double zoomScaleFactor;
      if (tileSizer.effectiveScale == 1.0) {
        canvas.scale(_scale, _scale);
        zoomScaleFactor = _scale;
      } else {
        tileSizer.apply(canvas);
        zoomScaleFactor = tileSizer.effectiveScale / _scale;
      }
      final tileClip =
          tileSizer.tileClip(Size.square(size), tileSizer.effectiveScale);

      final tile = TileSource(
          tileset: tileResponse.tileset!,
          rasterTileset: rasterTile,
          spriteAtlas: spriteAtlas,
          spriteIndex: _sprites?.index);
      Renderer(theme: _theme).render(canvas, tile,
          zoomScaleFactor: zoomScaleFactor,
          zoom: requestedTile.z.toDouble(),
          rotation: 0.0,
          clip: tileClip);

      final picture = recorder.endRecording();
      final image = await picture.toImage(size.toInt(), size.toInt());
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
