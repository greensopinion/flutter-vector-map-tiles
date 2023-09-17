import '../tile_identity.dart';

class TileState {
  final double zoom;
  final double zoomDetail;
  final double zoomScale;
  final double rotation;

  TileState(
      {required this.zoom,
      required this.zoomDetail,
      required this.zoomScale,
      required this.rotation});

  factory TileState.undefined() => TileState(
      zoom: double.negativeInfinity,
      zoomDetail: double.negativeInfinity,
      zoomScale: double.negativeInfinity,
      rotation: 0.0);

  @override
  operator ==(other) =>
      other is TileState &&
      other.zoom == zoom &&
      other.zoomDetail == zoomDetail &&
      other.zoomScale == zoomScale &&
      other.rotation == rotation;

  @override
  int get hashCode => Object.hash(zoom, zoomDetail, zoomScale, rotation);
}

typedef ZoomScaleFunction = double Function(int tileZoom);
typedef ZoomFunction = double Function();
typedef RotationFunction = double Function();

class TileStateProvider {
  final TileIdentity tile;
  final ZoomScaleFunction zoomScaleFunction;
  final ZoomFunction zoomFunction;
  final ZoomFunction zoomDetailFunction;
  final RotationFunction rotationFunction;

  TileStateProvider(this.tile, this.zoomScaleFunction, this.zoomFunction,
      this.zoomDetailFunction, this.rotationFunction);

  TileState provide() => TileState(
      zoom: zoomFunction(),
      zoomDetail: zoomDetailFunction(),
      zoomScale: zoomScaleFunction(tile.z),
      rotation: rotationFunction());
}
