import 'dart:async';
import 'dart:collection';
import 'dart:ui';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

class RendererPipeline {
  final ImageRenderer _renderer;
  final queue = ListQueue<_RenderingJob>();
  RendererPipeline(Theme theme)
      : _renderer = ImageRenderer(theme: theme, scale: _imageScale);

  Future<Image> renderImage(VectorTile tile,
      {required double zoomScaleFactor, required double zoom}) async {
    final job = _RenderingJob(tile, zoomScaleFactor, zoom);
    queue.add(job);
    if (queue.length == 1) {
      _scheduleOne();
    }
    return job.completer.future;
  }

  void _renderOne() async {
    final job = queue.removeLast();
    try {
      final image = await _renderer.render(job.tile,
          zoomScaleFactor: job.zoomScaleFactor, zoom: job.zoom);
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
  final VectorTile tile;
  final double zoomScaleFactor;
  final double zoom;

  _RenderingJob(this.tile, this.zoomScaleFactor, this.zoom);
}

int _imageScale = 3;
