import 'package:flutter/material.dart';

import '../model/map_properties.dart';
import '../model/tile_data_model.dart';
import 'tile_custom_painter.dart';

class TileWidget extends StatefulWidget {
  final TileDataModel model;
  final MapProperties mapProperties;

  TileWidget({required this.model, required this.mapProperties})
      : super(key: Key('tile_${model.tile.key()}'));

  @override
  State<StatefulWidget> createState() => TileWidgetState();
}

class TileWidgetState extends State<TileWidget> {
  @override
  void didUpdateWidget(covariant TileWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.model.tilePosition != widget.model.tilePosition) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: Key('tile_boundary_${widget.model.tile.key()}'),
      child: CustomPaint(
        painter: TileCustomPainter(
          mapProperties: widget.mapProperties,
          model: widget.model,
        ),
        size: widget.model.tilePosition.position.size,
        isComplex: true,
      ),
    );
  }
}
