import 'package:flutter/material.dart';
import 'package:vector_map_tiles/src/tile_identity.dart';

class GridTile extends StatefulWidget {
  final TileIdentity tileIdentity;

  const GridTile({required Key key, required this.tileIdentity})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _GridTileState();
  }
}

class _GridTileState extends State<GridTile> {
  @override
  Widget build(BuildContext context) {
    return Text(widget.tileIdentity.toString());
  }
}
