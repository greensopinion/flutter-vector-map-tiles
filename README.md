# [vector_map_tiles](https://pub.dev/packages/vector_map_tiles)

A plugin for [`flutter_map`](https://pub.dev/packages/flutter_map) that enables the use of vector tiles with slippy maps and Flutter.

Loads vector tiles from a source such as Mapbox or Stadia Maps, and renders them as a layer on a `flutter_map`.


<img src="https://raw.githubusercontent.com/greensopinion/flutter-vector-map-tiles/main/vector_map_tiles-example.png" alt="example screenshot" width="292"/> <img src="https://raw.githubusercontent.com/greensopinion/flutter-vector-map-tiles/main/vector_map_tiles-example-hillshade.png" alt="example screenshot" width="292"/>

See the [gallery](gallery/gallery.md) for more examples.

## Installing

Details on https://pub.dev/packages/vector_map_tiles

See [vector_map_tiles/install](https://pub.dev/packages/vector_map_tiles/install) for instructions on installing.

## Usage

Read the map style:

```dart
  Future<Style> _readStyle() => StyleReader(
          uri:
              'https://tiles.stadiamaps.com/styles/osm_bright.json?api_key={key}',
          apiKey: stadiaMapsApiKey,
          logger: const Logger.console())
      .read();
```

Create the map:

```dart
 FlutterMap(
    mapController: _controller,
    options: MapOptions(
        center: style.center ?? LatLng(49.246292, -123.116226),
        zoom: style.zoom ?? 10,
        maxZoom: 22,
        interactiveFlags: InteractiveFlag.drag |
            InteractiveFlag.flingAnimation |
            InteractiveFlag.pinchMove |
            InteractiveFlag.pinchZoom |
            InteractiveFlag.doubleTapZoom),
    children: [
      // normally you would see TileLayer which provides raster tiles
      // instead this vector tile layer replaces the standard tile layer
      VectorTileLayer(
          theme: style.theme,
          sprites: style.sprites,
          // tileOffset: TileOffset.mapbox, enable with mapbox
          tileProviders: style.providers),
    ],
  )
```

See the [example](example) for details.

### Customizing a Theme

A theme can be built-in to your application:

```dart
VectorTileLayer(theme: ThemeReader().read(_myTheme()), ...)
```

### Specifying Alternate Tiles

Tiles can be loaded from alternate sources:

```dart
VectorTileLayer(tileProviders: TileProviders(
                    {'openmaptiles': _tileProvider() },
                    ...)
                )

VectorTileProvider _tileProvider() => NetworkVectorTileProvider(
            urlTemplate: 'https://tiles.example.com/openmaptiles/{z}/{x}/{y}.pbf?api_key=$myApiKey',
            // this is the maximum zoom of the provider, not the
            // maximum of the map. vector tiles are rendered
            // to larger sizes to support higher zoom levels
            maximumZoom: 14),

```

### Tile Providers for other tile sources

| Format                                                    | Description                                                                         | Package                                                                       |
|-----------------------------------------------------------|-------------------------------------------------------------------------------------|-------------------------------------------------------------------------------|
| [PMTiles](https://docs.protomaps.com/pmtiles/)            | A binary file format to bundle tiles and use them from a web or file system source. | [vector_map_tiles_pmtiles](https://pub.dev/packages/vector_map_tiles_pmtiles) |
| [MBTiles](https://docs.mapbox.com/help/glossary/mbtiles/) | A commonly used file format to bundle tiles into a SQLite database.                 | [vector_map_tiles_mbtiles](https://pub.dev/packages/vector_map_tiles_mbtiles) |

## More Examples

A more complete example showing use of this library is available [in the examples repository `flutter-vector-map-tiles-examples`](https://github.com/greensopinion/flutter-vector-map-tiles-examples). The examples include use with multiple themes, tile providers, contours, hillshade and network-loaded styles.

## Themes and Tile Providers

Themes and tile providers must be matched to have a working configuration, since themes reference layers and properties in the vector tile.

While we don't test with all configurations, the following themes have been tested with this library:

Tiles from [Maptiler](https://maptiler.com) or [Stadia Maps](https://stadiamaps.com/)

* [OSM Liberty](https://maputnik.github.io/osm-liberty/style.json)
* [OSM Bright](https://cdn.jsdelivr.net/gh/openmaptiles/osm-bright-gl-style@v1.9/style.json)
* [Klokantech Basic](https://cdn.jsdelivr.net/gh/openmaptiles/klokantech-basic-gl-style@v1.9/style.json)
* [Dark Matter](https://cdn.jsdelivr.net/gh/openmaptiles/dark-matter-gl-style@v1.8/style.json)

Tiles from [mapbox](https://www.mapbox.com/)

* [Mapbox Outdoors](https://www.mapbox.com/maps/outdoors)
* [Mapbox Streets](https://www.mapbox.com/maps/streets)
* [Mapbox Light](https://www.mapbox.com/maps/light)
* [Mapbox Dark](https://www.mapbox.com/maps/dark)

Other combinations of theme/provider may work too.

Some tile providers offer tiles with more detail that are intended to be drawn at a higher zoom level. For example, Mapbox provdies tiles tiles that render at 512px instead of the default 256px ([Mapbox docs](https://docs.mapbox.com/help/glossary/zoom-level/#tile-size)). Set `VectorTileLayerOptions.tileOffset` with these providers. 
## Attribution

Examples provided in `vector_map_tiles` make use of Mapbox and Stadia Maps, both of which require attribution.
Be sure to read the terms of service of your tile data provider to ensure that you understand their attribution requirements.

## Upgrading

For guidance on upgrading from a previous version of this library, see the [Upgrading Guide](UPGRADING.md).

## Development

### Continuous Integration

CI with GitHub Actions:

[![CI status](https://github.com/greensopinion/flutter-vector-map-tiles/actions/workflows/CI.yaml/badge.svg)](https://github.com/greensopinion/flutter-vector-map-tiles/actions)

## License

Copyright 2021 David Green

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice,
   this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, 
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors
   may be used to endorse or promote products derived from this software without
   specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR 
BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, 
STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
 OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.