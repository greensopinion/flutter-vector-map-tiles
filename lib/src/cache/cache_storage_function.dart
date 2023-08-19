import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<Directory> cacheStorageResolver() async {
  final tempFolder = await getTemporaryDirectory();
  return Directory('${tempFolder.path}/.vector_map');
}
