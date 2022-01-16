import 'dart:math';

import 'tile_supplier.dart';

import '../../vector_map_tiles.dart';

class DelayProvider extends TileProvider {
  final TileProvider _delegate;
  final Duration _delay;
  final Random _random = Random();

  DelayProvider(this._delegate, this._delay);

  @override
  int get maximumZoom => _delegate.maximumZoom;

  TileProvider orDelegate() {
    if (_delay.inMilliseconds > 0) {
      return this;
    }
    return _delegate;
  }

  @override
  Future<Tile> provide(TileProviderRequest request) async {
    final tile = _delegate.provide(request);
    final durationWithJitter =
        Duration(milliseconds: _random.nextInt(_delay.inMilliseconds));
    await Future.delayed(durationWithJitter);
    return tile;
  }
}
