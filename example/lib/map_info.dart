import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

class MapInfo extends StatefulWidget {
  const MapInfo({super.key});

  @override
  State<StatefulWidget> createState() => _MapInfoState();
}

class _MapInfoState extends State<MapInfo> {
  StreamSubscription<MapEvent>? _subscription;

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = MapController.maybeOf(context);
    if (controller == null) {
      return const Center(child: Text('No MapController found in context'));
    } else {
      _subscription ??= controller.mapEventStream.listen((event) {
        if (mounted) {
          setState(() {});
        }
      });
      final center = controller.camera.center;
      final zoom = controller.camera.zoom;
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Center: ${center.latitude.toStringAsFixed(3)}, ${center.longitude.toStringAsFixed(3)}',
            ),
            Text('Zoom: ${zoom.toStringAsFixed(3)}'),
          ],
        ),
      );
    }
  }
}
