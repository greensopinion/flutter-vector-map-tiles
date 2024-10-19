import 'package:vector_map_tiles/src/cache/byte_storage_web.dart';

Future<String> cacheStorageResolver() async {
  return ByteStorage.storeName;
}
