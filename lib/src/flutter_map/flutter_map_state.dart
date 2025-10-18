import 'dart:ui';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../layout/map_state.dart';

class FlutterMapState extends MapState {
  final MapCamera camera;

  FlutterMapState({required this.camera});

  @override
  LatLng get center => camera.center;

  @override
  Offset get pixelOrigin =>
      camera.crs.latLngToOffset(center, zoom) -
      camera.nonRotatedSize.center(Offset.zero);

  @override
  double get zoom => camera.zoom;

  @override
  double getZoomScale(double fromZoom, double toZoom) =>
      camera.getZoomScale(fromZoom, toZoom);

  @override
  Offset projectAtZoom(LatLng center, double zoom) =>
      camera.projectAtZoom(center, zoom);

  @override
  Size get size => camera.size;
}
