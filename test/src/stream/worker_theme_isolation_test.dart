import 'package:executor_lib/executor_lib.dart';
import 'package:test/test.dart';
import 'package:vector_map_tiles/src/stream/tile_processor.dart';
import 'package:vector_map_tiles/src/stream/tile_supplier.dart';
import 'package:vector_map_tiles/src/stream/tileset_executor_preprocessor.dart';
import 'package:vector_map_tiles/src/tile_identity.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

int _ready(int value) => value;

TileData _data(String layer) => TileData(layers: [
      TileDataLayer(name: layer, extent: 4096, features: []),
    ]);

TileRequest _request() => TileRequest(
    tileId: TileIdentity(8, 156, 77),
    tileSources: {'basemap'},
    zoom: 8,
    zoomDetail: 8,
    cancelled: () => false);

Theme _theme(String id) => Theme(id: id, version: '1', layers: []);

void main() {
  late PoolExecutor executor;

  setUp(() async {
    executor = PoolExecutor(concurrency: 1);
    await executor.submit(Job('ready', _ready, 0, deduplicationKey: null));
  });
  tearDown(() => executor.dispose());

  test('different layer processors do not exchange processed tile data',
      () async {
    final geometry = TileProcessor(executor, _theme('geometry'));
    final labels = TileProcessor(executor, _theme('labels'));
    for (final labelsFirst in [true, false]) {
      final processors = labelsFirst ? [labels, geometry] : [geometry, labels];
      final expected =
          labelsFirst ? ['place', 'landcover'] : ['landcover', 'place'];
      final results = await Future.wait([
        for (var i = 0; i < processors.length; i++)
          processors[i]
              .process(_request(), 'basemap', _data(expected[i]), () => false),
      ]);
      expect(results.map((tile) => tile.layers.single.name), expected);
    }
  });

  test('different theme preprocessors do not exchange tilesets', () async {
    final geometry = TilesetExecutorPreprocessor(
        TilesetPreprocessor(_theme('geometry')), executor);
    final labels = TilesetExecutorPreprocessor(
        TilesetPreprocessor(_theme('labels')), executor);
    // Complete initialization before queuing the colliding jobs together.
    await Future.wait([
      for (final processor in [geometry, labels])
        processor.preprocess(
            TileIdentity(0, 0, 0),
            Tileset({'basemap': _data('ready').toTile()}),
            null,
            0,
            () => false),
    ]);
    for (final labelsFirst in [true, false]) {
      final processors = labelsFirst ? [labels, geometry] : [geometry, labels];
      final expected =
          labelsFirst ? ['place', 'landcover'] : ['landcover', 'place'];
      final results = await Future.wait([
        for (var i = 0; i < processors.length; i++)
          processors[i].preprocess(
              TileIdentity(8, 156, 77),
              Tileset({'basemap': _data(expected[i]).toTile()}),
              null,
              8,
              () => false),
      ]);
      expect(
          results.map((tileset) => tileset.tile('basemap')!.layers.single.name),
          expected);
    }
  });
}
