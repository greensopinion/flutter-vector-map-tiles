import 'dart:ui';

import 'package:latlong2/latlong.dart';
import 'package:vector_map_tiles/src/layout/map_state.dart';

class MockMapState implements MapState {
  @override
  final LatLng center;
  @override
  final double zoom;
  @override
  final Offset pixelOrigin;
  @override
  final Size size;

  MockMapState({
    required this.center,
    required this.zoom,
    required this.pixelOrigin,
    required this.size,
  });

  @override
  double getZoomScale(double fromZoom, double toZoom) {
    final zoomDiff = (toZoom - fromZoom).round();
    if (zoomDiff >= 0) {
      return 1.0 / (1 << zoomDiff);
    } else {
      return (1 << (-zoomDiff)).toDouble();
    }
  }

  @override
  Offset projectAtZoom(LatLng center, double zoom) {
    final scale = 256.0 * (1 << zoom.round());
    final x = (center.longitude + 180.0) / 360.0 * scale;
    final y = (1.0 - (center.latitude + 90.0) / 180.0) * scale;
    return Offset(x, y);
  }
}
