/// the mode of rendering
enum VectorTileLayerMode {
  /// The tile layer is rendered from vector data as
  /// raster images. This provides a similar experience
  /// to using raster tiles directly, with the advantage
  /// of client-side theming. Provides the best frame
  /// rate.
  raster,

  /// The tile layer is rendered as vectors, with each
  /// incremental zoom level having tiles re-rendered.
  /// Best for sharpness, but can result in low frame
  /// rates.
  vector
}
