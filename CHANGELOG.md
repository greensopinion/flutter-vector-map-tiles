## 1.3.45

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
