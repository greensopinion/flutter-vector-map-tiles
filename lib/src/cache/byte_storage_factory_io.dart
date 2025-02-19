import 'dart:io' as io;

import 'package:path_provider/path_provider.dart';

import 'byte_storage.dart';
import 'byte_storage_io.dart';

Future<io.Directory> cacheStorageResolver() async {
  final tempFolder = await getTemporaryDirectory();
  return io.Directory('${tempFolder.path}/.vector_map');
}

ByteStorage createByteStorage(Future<io.Directory> Function()? cacheFolder) =>
    IoByteStorage(pather: cacheFolder ?? cacheStorageResolver);
