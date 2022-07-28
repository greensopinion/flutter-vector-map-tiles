import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'byte_storage.dart';
import 'bytes_cache.dart';
import 'cache.dart';
import 'memory_async_cache.dart';
import 'storage_cache.dart';

AsyncBytesCache createBytesCache(
    {required Duration ttl, required int maxSizeInBytes}) {
  if (kIsWeb) {
    return MemoryAsyncBytesCache(BytesCache(maxSizeBytes: maxSizeInBytes));
  }
  final storage = ByteStorage(
      pather: () => getTemporaryDirectory()
          .then((value) => Directory('${value.path}/.vector_map')));
  return StorageCache(storage, ttl, maxSizeInBytes);
}
