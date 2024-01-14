import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../../vector_map_tiles.dart';
import 'debounce.dart';
import 'slippy_map_translator.dart';
import 'tile_model.dart';
import 'tile_zoom.dart';

class TileLayerModel extends ChangeNotifier {
  final String id;
  final Theme theme;
  final SpriteStyle? sprites;
  final Duration delay;
  final Duration initialDelay;
  Tileset? tileset;
  RasterTileset? rasterTileset;
  TileTranslation? translation;
  final VectorTileModel tileModel;
  var _disposed = false;
  var visible = true;
  late final ScheduledDebounce debounce;
  TileState lastRenderedState = TileState.undefined();
  var lastRenderedVisible = true;
  TileIdentity? lastRenderedTile;
  var _renderedOnce = false;

  ui.Image? spriteImage;

  TileLayerModel(
      {required this.theme,
      required this.sprites,
      required this.id,
      required this.delay,
      required this.initialDelay,
      required this.tileset,
      required this.tileModel}) {
    debounce = ScheduledDebounce(_makeVisible,
        delay: delay,
        jitter: Duration(milliseconds: delay.inMilliseconds ~/ 2),
        maxAge: Duration(milliseconds: delay.inMilliseconds * 20));
    tileModel.addListener(_modelUpdated);
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  void _modelUpdated() {
    if (visible &&
        _renderedOnce &&
        lastRenderedState != tileModel.stateProvider.provide()) {
      notifyListeners();
    }
  }

  void _makeVisible() {
    visible = true;
    notifyListeners();
  }

  TileState updateRendering() {
    final previousRenderedState = lastRenderedState;
    lastRenderedState = tileModel.stateProvider.provide();
    lastRenderedVisible = visible;
    lastRenderedTile = tileModel.translation?.translated;
    if (previousRenderedState != lastRenderedState &&
        nextDelay().inMilliseconds > 0) {
      visible = false;
      debounce.update();
    }
    if (visible) {
      _renderedOnce = true;
    }
    return lastRenderedState;
  }

  Duration nextDelay() {
    if (!_renderedOnce && initialDelay.inMilliseconds > 0) {
      return initialDelay;
    }
    return delay;
  }

  bool hasChanged() =>
      visible != lastRenderedVisible ||
      lastRenderedState != tileModel.stateProvider.provide() ||
      lastRenderedTile != tileModel.translation?.translated;
}
