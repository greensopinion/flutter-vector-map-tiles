import '../tile_identity.dart';

class TileZoom {
  final double zoom;
  final double zoomDetail;
  final double zoomScale;

  TileZoom(
      {required this.zoom, required this.zoomDetail, required this.zoomScale});

  factory TileZoom.undefined() => TileZoom(
      zoom: double.negativeInfinity,
      zoomDetail: double.negativeInfinity,
      zoomScale: double.negativeInfinity);

  @override
  operator ==(other) =>
      other is TileZoom &&
      other.zoom == zoom &&
      other.zoomDetail == zoomDetail &&
      other.zoomScale == zoomScale;

  @override
  int get hashCode => Object.hash(zoom, zoomDetail, zoomScale);
}

typedef ZoomScaleFunction = double Function(int tileZoom);
typedef ZoomFunction = double Function();

class TileZoomProvider {
  final TileIdentity tile;
  final ZoomScaleFunction zoomScaleFunction;
  final ZoomFunction zoomFunction;
  final ZoomFunction zoomDetailFunction;

  TileZoomProvider(this.tile, this.zoomScaleFunction, this.zoomFunction,
      this.zoomDetailFunction);

  TileZoom provide() => TileZoom(
      zoom: zoomFunction(),
      zoomDetail: zoomDetailFunction(),
      zoomScale: zoomScaleFunction(tile.z));
}
