import 'cache/caches.dart';

/// A controller for programmatic access to [VectorTileLayer] cache operations.
///
/// Create an instance and pass it to [VectorTileLayer.controller].
/// Use [clearMemoryCaches] to clear all in-memory caches on demand.
abstract class VectorTileController {
  /// Creates a [VectorTileController].
  factory VectorTileController() = _VectorTileControllerImpl;

  /// Clears all in-memory caches without adjusting their max sizes.
  ///
  /// If the controller is not attached to a widget, this is a no-op.
  void clearMemoryCaches();
}

class _VectorTileControllerImpl implements VectorTileController {
  Caches? _caches;

  @override
  void clearMemoryCaches() {
    _caches?.clearMemoryCaches();
  }

  void attach(Caches caches) {
    assert(_caches == null, 'VectorTileController is already attached');
    _caches = caches;
  }

  void detach() {
    _caches = null;
  }
}

/// Attaches the [controller] to the given [caches].
///
/// This is package-internal and not exported from the library barrel file.
void attachController(VectorTileController? controller, Caches caches) {
  (controller as _VectorTileControllerImpl?)?.attach(caches);
}

/// Detaches the [controller] from its caches.
///
/// This is package-internal and not exported from the library barrel file.
void detachController(VectorTileController? controller) {
  (controller as _VectorTileControllerImpl?)?.detach();
}
