## 8.0.0

* update `flutter_map` to version 7.0.2

## 7.3.1

* support cancellation in raster tile provider

## 7.3.0

* refactoring
* expose `ProviderException`

## 7.1.0

* support vector theme raster layers

## 7.0.1

* fix [issue 188](https://github.com/greensopinion/flutter-vector-map-tiles/issues/188) where raster mode map would be rotated incorrectly

## 7.0.0

* update `flutter_map` dependency to 6.1.0

See [UPGRADING](https://github.com/greensopinion/flutter-vector-map-tiles/blob/main/UPGRADING.md) for details.

## 6.0.2

* support concurrent use of different map themes in the same application

## 6.0.1

* eliminate noise from disposed `ImageStreamCompleter` since it's expected

## 6.0.0

* support icon/text rotation to align with viewport

## 5.0.0

* support layer `minzoom`
* support application-provided cache folder via `VectorTileLayer.cacheFolder`
* update to flutter_map 5.0.0

## 4.0.0

* update to flutter_map 4.0.0
* add support for icons via sprites

## 3.3.5

* minor optimization
## 3.3.4

* evict oldest entries from cache when cache max size is exceeded

## 3.3.3

* fix concurrency issue affecting styles with multiple tile sources

## 3.3.2

* limit raster tile rendering concurrency

## 3.3.1

* fix issue where tiles would not dynamically change when theme changed

## 3.3.0

* introduce new option, `layerMode`
* improve frame rate by rendering vector tiles to raster images
* behaviour change: defaults to providing raster tiles for rendering, set `layerMode = TileLayerMode.vector` to match previous versions

## 3.2.0

* Add `StyleReader` to API

## 3.1.3

* add support for more expressions
* reduce invalid tile coordinate requests

## 3.1.2

* extract executors to `executor_lib` package

## 3.0.2

* minor performance improvement
## 3.0.1

* improve support for theme expressions
## 3.0.0

* support `flutter_map` 3.0.0

## 2.4.1

* fix performance regression on Flutter 3.3.1 when running in debug mode

## 2.4.0

* improve usage on a slow internet connection by displaying lower zoom tiles from the cache while loading tiles
* reduce chances of high memory usage

## 2.3.0

* support flutter_map 2.1

## 2.2.2

* provide support for dashed paths with `line-dasharray` theme style

## 2.2.1

* improve label halo at high zoom levels
## 2.2.0

* improve support for overzoom

## 2.1.2

* performance improvements

## 2.1.1

* update to flutter_map 1.1.0
## 2.1.0

* update to flutter_map 1.0.0

## 2.0.1

* added minimal support for fill-extrusion polygons
## 2.0.0

* removed mixed-mode and raster-mode rendering
## 1.5.1

* reduce occurrences of unhandled cancellation exception
## 1.5.0

* improved frame rate during animations
* text labels fade in to create improved transitions
## 1.4.10

* performance improvement
## 1.4.8

* support tile providers with different zoom offsets, for details see `VectorTileLayerOptions.tileOffset` 
* support line-cap and line-join layout

## 1.4.6

* text halo color can now use expressions
* add support for text-justify and text-max-width
* bug fix to theme filters that reference zoom level
* improve support for color expressions
* add support for case expressions
* support let and var expressions
* add support for cubic-bezier interpolation

## 1.4.4

* added support for more theme expressions: math, coalesce, step
* theme background color and text anchor can now use expressions

## 1.4.3

* improved error handling to reduce uncaught exceptions
## 1.4.2

* fixed issue where tiles occasionally wouldn't render when using a background theme
## 1.4.1

* bug fixes
* performance improvements
* reduced flicker when zooming
## 1.4.0

* performance improvements
* removed deprecated options
* added MacOS to example platforms
* added concurrency option to enable/disable use of isolates
* moved symbol rendering to a layer when rendering in vector mode
* reduce memory overhead
## 1.3.46

* reduce memory overhead even more
## 1.2.44

* performance improvement
* reduce memory overhead
* eliminate use of isolates since it's not stable enough for production usage
## 1.2.43

* reduce memory overhead
* improve mixed mode efficiency by preferring to render tiles once if vector data is availble before image data
## 1.2.40

* improve rendering speed by moving some tile processing and protobuf decoding to an isolate
* reduce flicker when zooming by rendering existing tiles until new tiles are ready

## 1.2.39

* consume latest `vector_tile_renderer` to:
* improve rendering speed
* improve label placement to have fewer unlabelled roads
* improve support for theme expressions

## 1.2.38

* reduce CPU overhead when rendering tiles

## 1.2.37

* improve backgound layer rendering

## 1.1.35

* consume upstream performance improvements
* fix crash when background theme not specified
## 1.1.31

* provide an option to render a background at a lower zoom level when tile data is loading
* improve cache hit rate when concurrently accessed
* improve background layer rendering
* reduce memory usage

## 1.1.27

* eliminate unnecessary re-rendering of tiles when panning
## 1.1.26

* update example
## 1.1.25

* support multiple tile sources so that data such as hillshade can be rendered on a map

## 1.0.22

* provide a `VectorTileLayerWidget` as an alternative to `VectorTileLayerOptions`
## 1.0.21

* reduce noise from file cache errors
## 1.0.20

* reduce memory overhead
## 1.0.19

* eliminate exception in tile cache when image data is invalid
## 1.0.17

* fail quietly on retryable network failures
## 1.0.16

* simplify socket management
## 1.0.15

* eliminate resource leak by closing http client when idle
* retry loading tiles on retryable errors, reduce exception noise
## 1.0.13

* expand compatibility to include latest `flutter_map` release 0.14.0
## 1.0.12

* improve place name abbreviations

## 1.0.11

* add theme version to cache key to enable theme providers to invalidate the cache
## 1.0.9

* improve label layout
* add place name abbreviations

## 1.0.7

* improve stability
## 1.0.6

* reduce unnecessary tile repaints
* add jitter to mixed mode tile repaints
## 1.0.4

* improve support for text
## 1.0.3

* eliminate occasional hairline gap between tiles
* improve tile appearance when zooming to zoom levels higher than the tile size

## 1.0.1

* use theme ID to segregate cached tiles by theme
## 1.0.0

* release
## 0.1.3

* add option for raster-only images
* add debug tile option
## 0.1.2

* image memory cache is conigurable
## 0.1.1

* reduce memory usage
* add storage-based cache
## 0.1.0

* add mixed mode rendering
## 0.0.8

* improve rendering speed with a repaint boundary
* reduce memory overhead by caching fewer tiles
## 0.0.7

* improve transition between tile sizes by rendering larger tiles while zooming smaller tiles
* improve performance by retaining some parsed vector tile data in memory
## 0.0.6

* remove debounce because it's not needed and adds jitter
## 0.0.5

* improve performance
* reduce zoom scalling oversize effect on lines such as roads
## 0.0.4

* improve line size interpolation
## 0.0.2

* support zoom levels higher than the maximum supported by
  the map tile provider.

## 0.0.1

* Initial version
