import 'package:test/test.dart';
import 'package:vector_map_tiles/src/slippy_map_translator.dart';
import 'package:vector_map_tiles/src/tile_identity.dart';

void main() {
  test('provides the identity translation', () {
    final translator = SlippyMapTranslator(15);
    final tile = TileIdentity(15, 253, 4023);
    final translation = translator.translate(tile);
    expect(translation.fraction, 1);
    expect(translation.original, tile);
    expect(translation.translated, tile);
    expect(translation.xOffset, 0);
    expect(translation.yOffset, 0);
  });

  test('provides a zoom translation at 2,0,0 to z 1', () {
    final translator = SlippyMapTranslator(1);
    final tile = TileIdentity(2, 0, 0);
    final translation = translator.translate(tile);
    expect(translation.fraction, 2);
    expect(translation.original, tile);
    expect(translation.translated.z, 1);
    expect(translation.translated.x, 0);
    expect(translation.translated.y, 0);
    expect(translation.xOffset, 0);
    expect(translation.yOffset, 0);
  });

  test('provides a zoom translation at 2,1,1 to z 1', () {
    final translator = SlippyMapTranslator(1);
    final tile = TileIdentity(2, 1, 1);
    final translation = translator.translate(tile);
    expect(translation.fraction, 2);
    expect(translation.original, tile);
    expect(translation.translated.z, 1);
    expect(translation.translated.x, 0);
    expect(translation.translated.y, 0);
    expect(translation.xOffset, 1);
    expect(translation.yOffset, 1);
  });
  test('provides a zoom translation at 3,7,7 to z 2', () {
    final translator = SlippyMapTranslator(2);
    final tile = TileIdentity(3, 7, 7);
    final translation = translator.translate(tile);
    expect(translation.fraction, 2);
    expect(translation.original, tile);
    expect(translation.translated.z, 2);
    expect(translation.translated.x, 3);
    expect(translation.translated.y, 3);
    expect(translation.xOffset, 1);
    expect(translation.yOffset, 1);
  });

  test('provides a zoom translation at 3,5,5 to z 2', () {
    final translator = SlippyMapTranslator(2);
    final tile = TileIdentity(3, 5, 5);
    final translation = translator.translate(tile);
    expect(translation.fraction, 2);
    expect(translation.original, tile);
    expect(translation.translated.z, 2);
    expect(translation.translated.x, 2);
    expect(translation.translated.y, 2);
    expect(translation.xOffset, 1);
    expect(translation.yOffset, 1);
  });

  test('provides a zoom translation at 3,2,5 to z 2', () {
    final translator = SlippyMapTranslator(2);
    final tile = TileIdentity(3, 2, 5);
    final translation = translator.translate(tile);
    expect(translation.fraction, 2);
    expect(translation.original, tile);
    expect(translation.translated.z, 2);
    expect(translation.translated.x, 1);
    expect(translation.translated.y, 2);
    expect(translation.xOffset, 0);
    expect(translation.yOffset, 1);
  });
}
