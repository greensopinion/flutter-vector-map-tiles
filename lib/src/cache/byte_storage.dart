// Import conditionally based on platform
export 'byte_storage_web.dart' if (dart.library.io) 'byte_storage_mobile.dart';

