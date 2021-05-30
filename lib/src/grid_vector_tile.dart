import 'package:flutter/widgets.dart';
import 'package:vector_map_tiles/src/tile_identity.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import 'disposable_state.dart';
import 'vector_tile_provider.dart';

class GridVectorTile extends StatefulWidget {
  final TileIdentity tileIdentity;
  final VectorTileProvider tileProvider;
  final Theme theme;

  const GridVectorTile(
      {required Key key,
      required this.tileIdentity,
      required this.tileProvider,
      required this.theme})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _GridVectorTile();
  }
}

class _GridVectorTile extends DisposableState<GridVectorTile> {
  VectorTile? _tile;

  @override
  void initState() {
    super.initState();
    widget.tileProvider.provide(widget.tileIdentity).then((bytes) {
      if (!disposed) {
        setState(() {
          this._tile = VectorTileReader().read(bytes);
        });
      }
    }).onError((error, stackTrace) {
      print(error);
      print(stackTrace);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_tile == null) {
      return Container();
    }
    return CustomPaint(
        painter: _VectorTilePainter(widget.tileIdentity, _tile!, widget.theme));
  }
}

class _VectorTilePainter extends CustomPainter {
  final TileIdentity _tileIdentity;
  final VectorTile _tile;
  final Theme _theme;

  _VectorTilePainter(this._tileIdentity, this._tile, this._theme);

  @override
  void paint(Canvas canvas, Size size) {
    Renderer(theme: _theme)
        .render(canvas, _tile, zoom: _tileIdentity.z.toInt());
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
