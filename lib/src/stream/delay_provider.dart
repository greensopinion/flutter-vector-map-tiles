import 'dart:math';

import 'tile_supplier.dart';

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
  Future<TileResponse> provide(TileRequest request) async {
    final tile = _delegate.provide(request);
    final durationWithJitter =
        Duration(milliseconds: _random.nextInt(_delay.inMilliseconds));
    await Future.delayed(durationWithJitter);
    return tile;
  }

  @override
  Future<TileResponse> provideLocalCopy(TileRequest request) =>
      _delegate.provideLocalCopy(request);
}
