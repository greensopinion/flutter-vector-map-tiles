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
    final durationWithJitter =
        Duration(milliseconds: _random.nextInt(_delay.inMilliseconds));
    // Await the tile together with the delay: if the tile fails during the
    // delay (e.g. it is cancelled), its error has a listener.
    final results = await Future.wait<Object?>(
        [_delegate.provide(request), Future<void>.delayed(durationWithJitter)],
        eagerError: true);
    return results.first as TileResponse;
  }

  @override
  Future<TileResponse> provideLocalCopy(TileRequest request) =>
      _delegate.provideLocalCopy(request);
}
