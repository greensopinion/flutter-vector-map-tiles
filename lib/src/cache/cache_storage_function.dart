// Import conditionally based on platform
export 'cache_storage_function_web.dart' if (dart.library.io) 'cache_storage_function_mobile.dart';

