import 'package:flutter/painting.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import 'cache.dart';

class TextCache extends Cache<StyledSymbol, TextPainter> {
  TextCache({required super.maxSize}) : super(sizer: Sizer(), copier: Copier());
}

class CachingTextPainterProvider extends TextPainterProvider {
  final TextCache _cache;
  final CreatedTextPainterProvider _delegate;

  CachingTextPainterProvider(this._cache, this._delegate);

  @override
  TextPainter? provide(StyledSymbol symbol) =>
      _delegate.provide(symbol) ?? _cache.get(symbol);
}
