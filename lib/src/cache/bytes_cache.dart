import 'dart:typed_data';

import 'memory_cache.dart';

class BytesCache extends MemoryCache<String, Uint8List> {
  BytesCache({required int maxSizeBytes})
      : super(maxSize: maxSizeBytes, sizer: _Sizer(), copier: Copier());
}

class _Sizer extends Sizer<Uint8List> {
  @override
  int size(Uint8List value) => value.lengthInBytes;
}
