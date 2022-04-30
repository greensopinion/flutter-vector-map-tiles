import 'package:flutter/painting.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import 'cache.dart';

class TextCache extends Cache<StyledSymbol, TextPainter> {
  TextCache({required int maxSize})
      : super(maxSize: maxSize, sizer: Sizer(), copier: Copier());
}

class CachingTextPainterProvider extends TextPainterProvider {
  final TextCache _cache;
  final TextPainterProvider _delegate;

  CachingTextPainterProvider(this._cache, this._delegate);

  @override
  TextPainter? provide(StyledSymbol symbol) =>
      _cache.get(symbol) ?? _delegate.provide(symbol);
}
