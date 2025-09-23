# [vector_map_tiles](https://pub.dev/packages/vector_map_tiles)

A plugin for [`flutter_map`](https://pub.dev/packages/flutter_map) that enables the use of vector tiles with slippy maps and Flutter.

Loads vector tiles from a source such as Mapbox or Stadia Maps, and renders them as a layer on a `flutter_map`.

## Flutter GPU Preview

This version of vector_map_tiles has a new rendering backend which makes use of ``flutter_gpu`` to achieve better performance. 
Please note that this branch is in preview state — we encourage you to try it out and share your feedback. If you encounter 
any bugs, performance issues, or have suggestions for improvements, please [open an issue with this template](https://github.com/greensopinion/flutter-vector-map-tiles/issues/new?template=10-0-0-gpu-issue.md) so we can continue refining 
and stabilizing.

### Known Issues

Issues for incomplete/unimplemented features, defects, questions and feedback: [issues label:10.0.0](https://github.com/greensopinion/flutter-vector-map-tiles/issues?q=state%3Aopen%20label%3A10.0.0)

<img src="https://raw.githubusercontent.com/greensopinion/flutter-vector-map-tiles/main/vector_map_tiles-example.png" alt="example screenshot" width="292"/> <img src="https://raw.githubusercontent.com/greensopinion/flutter-vector-map-tiles/main/vector_map_tiles-example-hillshade.png" alt="example screenshot" width="292"/>

See the [gallery](gallery/gallery.md) for more examples.

## Installing

Setup instructions have changed for the purposes of the 10.0.0 preview. Once released, it will be available on pub.dev.

vector_map_tiles depends on vector_tile_renderer. To set this up, run:
```shell
git clone git@github.com:greensopinion/flutter-vector-map-tiles.git vector_map_tiles
git clone git@github.com:greensopinion/dart-vector-tile-renderer.git vector_tile_renderer

cd vector_map_tiles
git checkout -b 10.0.0 origin/10.0.0
cd ..

cd vector_tile_renderer
git checkout -b 7.0.0 origin/7.0.0
cd ..
```

This version of vector_map_tiles also depends on``flutter_gpu``, which is currently available on the main flutter channel. To setup, run:

```shell
flutter channel main && flutter upgrade
```

Impeller must be enabled. Read on how to enable impeller [here](https://docs.flutter.dev/perf/impeller#availability).

Flutter GPU must also be enabled via the Flutter GPU manifest setting. This can be done either via command line argument --enable-flutter-gpu or by adding the FLTEnableFlutterGPU key set to true on iOS / MacOS or io.flutter.embedding.android.EnableFlutterGPU metadata key to true on Android. This is already done in the example project for iOS and MacOS.

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

## Elevation Contours from DEM (Beta)

Elevation contour lines are available by adding a `raster-dem` tile source. 
See the example:
* [creating a DEM tile source](https://github.com/greensopinion/flutter-vector-map-tiles-examples/blob/main/lib/examples/contours_from_terrarium_dem.dart#L24)
* [add contour lines to the theme](https://github.com/greensopinion/flutter-vector-map-tiles-examples/blob/main/lib/examples/light_custom_theme.dart#L132-L173)
* [add elevation labels to the theme](https://github.com/greensopinion/flutter-vector-map-tiles-examples/blob/main/lib/examples/light_custom_theme.dart#L1166-L1190)

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