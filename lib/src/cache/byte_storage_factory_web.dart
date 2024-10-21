import '../io/io.dart';
import 'byte_storage.dart';
import 'byte_storage_idb.dart';

ByteStorage createByteStorage(Future<Directory> Function()? cacheFolder) =>
    IdbByteStorage();
