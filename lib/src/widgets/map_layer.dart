import 'dart:async';
import 'dart:isolate';
import 'dart:ui';
import 'dart:typed_data';

import 'package:executor_lib/executor_lib.dart';
import 'package:flutter/widgets.dart' hide Image;
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../../vector_map_tiles.dart';
import '../loader/caching_tile_loader.dart';
import '../loader/theme_repo.dart';
import '../model/map_properties.dart';
import '../model/tile_data_model.dart';
import 'abstract_map_layer_state.dart';

class MapLayer extends AbstractMapLayer {
  const MapLayer({super.key, required super.mapProperties})
      : super(tileLoaderFactory: createCachingTileLoader);

  @override
  State<StatefulWidget> createState() => MapLayerState();
}

class MapLayerState extends AbstractMapLayerState<MapLayer> {
  late final TilesRenderer tilesRenderer;
  var _ready = false;
  List<String> _previousTileKeys = [];

  Image? loadedSpriteAtlas;

  @override
  void initState() {
    super.initState();
    tilesRenderer = TilesRenderer(widget.mapProperties.theme);
    TilesRenderer.initialize.then(_initialized);
  }

  @override
  void dispose() {
    super.dispose();
    tilesRenderer.dispose();
  }

  @override
  void didUpdateWidget(covariant MapLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mapProperties.theme != widget.mapProperties.theme) {
      tilesRenderer.dispose();
      tilesRenderer = TilesRenderer(widget.mapProperties.theme);
      super.resetState();
    }
  }

  @override
  Future<void> preRender(TileDataModel tile) {
    return super.preRender(tile).then((_) async {
      final tileset = tile.tileset ?? Tileset({});
      final tileID = tile.tile.key();
      final theme = widget.mapProperties.theme;

      final preRenderData = tileset.tiles.values
          .fold(<Map<String, Uint8List>>[], (a, b) => a..add(b.prerenderData));

      final remainingTheme = Theme(
          layers: theme.layers
              .where((layer) => tilesRenderer.isPreRenderLayer(layer.type))
              .toList(),
          id: theme.id,
          version: theme.version);

      final optimizedTileset = Tileset(tileset.tiles.map((key, value) =>
          MapEntry(key, remainingTheme.optimizeTile(value, zoom))));

      final jobArguments = (
        theme.id,
        zoom,
        optimizedTileset,
        tileID,
        widget.mapProperties.tileOffset.zoomOffset
      );

      await tilesRenderer.preRenderUi(zoom, tileset, tileID);
      await executor
          .submit(Job(
        "pre-render",
        _preRender(),
        jobArguments,
        deduplicationKey:
            "pre-render:${widget.mapProperties.theme.id}-${widget.mapProperties.theme.version}-$zoom-${tile.tile.key()}",
      ))
          .then((renderData) {
        try {
          tile.renderData = [
            ...preRenderData,
            renderData.map((k, v) => MapEntry(k, v.materialize().asUint8List()))
          ];
        } catch (_) {}
      });
    });
  }

  Map<String, TransferableTypedData> Function(
      (String, double, Tileset, String, int) args) _preRender() {
    final preRenderer = tilesRenderer.getPreRenderer();
    return ((String, double, Tileset, String, int) args) {
      final theme = ThemeRepo.themeById[args.$1]!;
      return preRenderer
          .call(theme, args.$2, args.$3, args.$4, args.$5)
          .map((k, v) => MapEntry(k, TransferableTypedData.fromList([v])));
    };
  }

  @override
  Widget build(BuildContext context) {
    updateTiles(context);
    if (!_ready) {
      return Container();
    }
    final tileModels = mapTiles.tileModels
        .where((it) => it.isDisplayReady)
        .toList(growable: false);
    final uiTiles = tileModels
        .map((it) =>
            it.toUiModel(widget.mapProperties.sprites, loadedSpriteAtlas))
        .toList(growable: false);

    final currentTileKeys = uiTiles.map((it) => it.tileId.key()).toList();
    if (!_tilesEqual(currentTileKeys, _previousTileKeys)) {
      _previousTileKeys = currentTileKeys;
      onTilesChanged();
    }

    tilesRenderer.update(
        zoom, uiTiles, mapTiles.tileModels.map((it) => it.tile.key()));

    return CustomPaint(
      key: Key(
        'mapTileLayer_${widget.mapProperties.theme.id}_${widget.mapProperties.theme.version}',
      ),
      painter: MapTilesPainter(widget.mapProperties, tilesRenderer, rotation),
      isComplex: true,
    );
  }

  bool _tilesEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    final setA = a.toSet();
    final setB = b.toSet();
    return setA.length == setB.length && setA.containsAll(setB);
  }

  FutureOr _initialized(void value) async {
    if (mounted) {
      loadedSpriteAtlas = await (spriteAtlas!);
      setState(() {
        _ready = true;
      });
    }
  }
}

class MapTilesPainter extends CustomPainter {
  final MapProperties properties;
  final TilesRenderer tilesRenderer;
  final double rotation;

  MapTilesPainter(this.properties, this.tilesRenderer, this.rotation);

  @override
  void paint(Canvas canvas, Size size) {
    tilesRenderer.render(canvas, size, rotation);
  }

  @override
  bool shouldRepaint(covariant MapTilesPainter oldDelegate) => true;
}

extension _TileDataModelUiExtension on TileDataModel {
  TileUiModel toUiModel(SpriteStyle? sprites, Image? spriteAtlas) =>
      TileUiModel(
        tileId: tile.toTileId(),
        position: tilePosition.position,
        tileSource: TileSource(
          tileset: tileset ?? Tileset({}),
          rasterTileset: rasterTileset ?? const RasterTileset(tiles: {}),
          spriteIndex: sprites?.index,
          spriteAtlas: spriteAtlas,
        ),
        renderData: renderData,
      );
}

extension _TileIdExtension on TileIdentity {
  TileId toTileId() => TileId(z: z, x: x, y: y);
}
