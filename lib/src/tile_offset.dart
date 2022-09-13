/// Describes a tile size and zoom offset so that loaded tiles can be used to
/// render a larger or smaller area.
class TileOffset {
  /// [zoomOffset] the zoom offset, usually 0. A negative offset will cause tiles
  /// to be loaded at a lower zoom level than normal. E.g. a zoomOffset of -1 will
  /// cause the map to load tiles at zoom level 13 when the map is at zoom level 14.
  final int zoomOffset;

  const TileOffset({required this.zoomOffset});

  /// The default tile offset with size 256.0 and zoomOffset 0
  // ignore: constant_identifier_names
  static const DEFAULT = TileOffset(zoomOffset: 0);

  /// A tile offset corresponding to that recommended by Mapbox
  /// https://docs.mapbox.com/help/glossary/zoom-level/#tile-size
  static final mapbox = DEFAULT.offsetBy(zoom: -1);

  /// provides an offset relative to this one.
  ///
  /// [zoom] the zoom of the offset. For example, for a tile size of 256 and
  ///         offset of 0, providing a [zoom] of -1 will produce an offset with
  ///         tile size 512 and zoomOffset of -1
  TileOffset offsetBy({required int zoom}) {
    if (zoom == 0) {
      return this;
    }
    assert(zoom < 0);

    return TileOffset(zoomOffset: zoomOffset + zoom);
  }
}
