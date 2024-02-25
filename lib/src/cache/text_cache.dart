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

class InlineCachingTextPainterProvider extends TextPainterProvider {
  final TextCache _cache;
  final TextPainterProvider _delegate;

  InlineCachingTextPainterProvider(this._cache, this._delegate);

  @override
  TextPainter? provide(StyledSymbol symbol) =>
      _cache.get(symbol) ?? _create(symbol);

  TextPainter? _create(StyledSymbol symbol) {
    final painter = _delegate.provide(symbol);
    if (painter != null) {
      _cache.put(symbol, painter);
    }
    return painter;
  }
}
