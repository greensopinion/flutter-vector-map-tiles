import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'dart:ui';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import './tile_identity.dart';

class RendererPipeline {
  late final ImageRenderer _renderer;
  final queue = ListQueue<_RenderingJob>();
  final double scale;
  RendererPipeline(Theme theme, {required this.scale}) {
    _renderer = ImageRenderer(theme: theme, scale: scale);
  }

  Future<Image> renderImage(
      TileIdentity id, VectorTile tile, double zoom) async {
    final job = _RenderingJob(id, tile, zoom);
    queue.add(job);
    if (queue.length == 1) {
      _scheduleOne();
    }
    return job.completer.future;
  }

  void _renderOne() async {
    final job = queue.removeLast();
    try {
      int zoomDifference = job.zoom.toInt() - job.id.z.toInt();
      final image = await _renderer.render(job.tile,
          zoomScaleFactor: scale * zoomDifference, zoom: job.zoom);
      job.completer.complete(image);
    } catch (error, stack) {
      print(error);
      print(stack);
      job.completer.completeError(error);
    }
  }

  void _scheduleOne() {
    scheduleMicrotask(() {
      _renderOne();
      if (queue.isNotEmpty) {
        _scheduleOne();
      }
    });
  }
}

class _RenderingJob {
  final completer = Completer<Image>();
  final TileIdentity id;
  final VectorTile tile;
  final double zoom;

  _RenderingJob(this.id, this.tile, this.zoom);
}
