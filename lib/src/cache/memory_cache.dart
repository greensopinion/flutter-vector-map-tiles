import 'dart:typed_data';

import 'cache.dart';

class MemoryCache extends Cache<String, Uint8List> {
  MemoryCache({required int maxSizeBytes})
      : super(maxSize: maxSizeBytes, sizer: _Sizer(), copier: Copier());
}

class _Sizer extends Sizer<Uint8List> {
  @override
  int size(Uint8List value) => value.lengthInBytes;
}
