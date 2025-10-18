import 'package:vector_map_tiles/src/layout/zoom_scaler.dart';

class MockZoomScaler implements ZoomScaler {
  final double _scale;

  MockZoomScaler(this._scale);

  @override
  double Function(double zoom) get zoomScale => (zoom) => _scale;

  @override
  void updateMapZoomScale(double mapZoom) {
    // Mock implementation - no-op for testing
  }

  @override
  double tileScale({required int tileZoom}) => _scale;
}
