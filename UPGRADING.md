## Upgrading

This guide provides details for upgrading from older versions of the library.


### From 6.x.x to 7.0.0

Version 7.x updates `flutter_map` dependency to version 6.1. See the [flutter_map v6 migration docs](https://docs.fleaflet.dev/getting-started/migrating-to-v6) for details.

Notably, this libarry no longer provides a background color from the material theme. To retain previous behaviour, 
set the following: `MapOptions(backgroundColor: material.Theme.of(context).canvasColor)`

### From 3.2.x to 3.3.0

Version 3.3 changes behaviour: instead of rendering vector tiles directly to a canvas, vector tiles are first rendered to an image. This improves the frame rate and reduces jank, but produces tiles that can be less sharp at some zoom levels due to scaling. 

Memory space, filesystem storage for caching and CPU usage will change, depending on the device. 

To maintain previous behaviour set `layerMode = TileLayerMode.vector` on the `VectorTileLayer`.

### From 2.x to 3.0.0

Upgrading to version 3.0.0 requires using [flutter_map 3.x](https://pub.dev/packages/flutter_map), which includes some breaking changes as described in the [flutter_map documentation](https://docs.fleaflet.dev/migration/to-v3.0.0).

Notable changes to `vector_map_tiles` when upgrading to 3.0.0:

* `VectorTileLayerOptions` has been removed from API, instead use `VectorTileLayer`
* `VectorMapTilesPlugin` has been removed from API, it is no longer needed
* Constants starting with `VectorTileLayerOptions.DEFAULT_*` in `VectorTileLayerOptions` have been renamed with camel-case to `VectorTileLayer.default*`