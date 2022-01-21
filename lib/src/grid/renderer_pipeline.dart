import 'dart:async';
import 'dart:collection';
import 'dart:ui';
import '../executor/executor.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../tile_identity.dart';

class RendererPipeline {
  final Theme theme;
  late final ImageRenderer _renderer;
  final queue = ListQueue<_RenderingJob>();
  final double scale;
  RendererPipeline(this.theme, {required this.scale}) {
    _renderer = ImageRenderer(theme: theme, scale: scale);
  }

  Future<Image> renderImage(TileIdentity id, Tileset tileset, int zoom,
      {required CancellationCallback cancelled}) async {
    final job = _RenderingJob(id, tileset, zoom, cancelled);
    queue.add(job);
    if (queue.length == 1) {
      _scheduleOne();
    }
    return job.completer.future;
  }

  Future<void> _renderOne() async {
    if (queue.isEmpty) {
      return;
    }
    final job = queue.removeLast();
    try {
      if (job.cancelled()) {
        throw CancellationException();
      }
      int zoomDifference = job.zoom.toInt() - job.id.z.toInt();
      final image = await _renderer.render(job.tileset,
          zoomScaleFactor: scale * zoomDifference, zoom: job.zoom.toDouble());
      job.completer.complete(image);
    } catch (error, stack) {
      print(error);
      print(stack);
      job.completer.completeError(error);
    }
  }

  void _scheduleOne() {
    scheduleMicrotask(() async {
      await _renderOne();
      if (queue.isNotEmpty) {
        _scheduleOne();
      }
    });
  }
}

class _RenderingJob {
  final completer = Completer<Image>();
  final TileIdentity id;
  final Tileset tileset;
  final int zoom;
  final CancellationCallback cancelled;

  _RenderingJob(this.id, this.tileset, this.zoom, this.cancelled);
}
