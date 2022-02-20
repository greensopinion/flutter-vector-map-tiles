# [vector_map_tiles](https://pub.dev/packages/vector_map_tiles)

A plugin for [`flutter_map`](https://pub.dev/packages/flutter_map) that enables the use of vector tiles with slippy maps and Flutter.

Loads vector tiles from a source such as Mapbox or Stadia Maps, and renders them as a layer on a `flutter_map`.

Tile rendering can be vector, mixed, or raster. Mixed mode is default, since that provides an optimal trade-off between sharp visuals when idle, and smooth animation when zooming with a pinch gesture.

<img src="https://raw.githubusercontent.com/greensopinion/flutter-vector-map-tiles/main/vector_map_tiles-example.png" alt="example screenshot" width="292"/> <img src="https://raw.githubusercontent.com/greensopinion/flutter-vector-map-tiles/main/vector_map_tiles-example-hillshade.png" alt="example screenshot" width="292"/>

## Installing

Details on https://pub.dev/packages/vector_map_tiles

See [vector_map_tiles/install](https://pub.dev/packages/vector_map_tiles/install) for instructions on installing.

## Usage

```dart
class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: SafeArea(
            child: Column(children: [
          Flexible(
              child: FlutterMap(
            options: MapOptions(
                center: LatLng(49.246292, -123.116226),
                zoom: 10,
                maxZoom: 15,
                plugins: [VectorMapTilesPlugin()]),
            layers: <LayerOptions>[
              // normally you would see TileLayerOptions which provides raster tiles
              // instead this vector tile layer replaces the standard tile layer
              VectorTileLayerOptions(
                  theme: _mapTheme(context),
                  tileProviders: TileProviders(
                      {'openmaptiles': _cachingTileProvider(_urlTemplate())})),
            ],
          ))
        ])));
  }

  VectorTileProvider _cachingTileProvider(String urlTemplate) {
    return MemoryCacheVectorTileProvider(
        delegate: NetworkVectorTileProvider(
            urlTemplate: urlTemplate,
            // this is the maximum zoom of the provider, not the
            // maximum of the map. vector tiles are rendered
            // to larger sizes to support higher zoom levels
            maximumZoom: 14),
        maxSizeBytes: 1024 * 1024 * 2);
  }

  _mapTheme(BuildContext context) {
    // maps are rendered using themes
    // to provide a dark theme do something like this:
    // if (MediaQuery.of(context).platformBrightness == Brightness.dark) return myDarkTheme();
    return ProvidedThemes.lightTheme();
  }

  String _urlTemplate() {
    // Stadia Maps source https://docs.stadiamaps.com/vector/
    return 'https://tiles.stadiamaps.com/data/openmaptiles/{z}/{x}/{y}.pbf?api_key=$apiKey';

    // Mapbox source https://docs.mapbox.com/api/maps/vector-tiles/#example-request-retrieve-vector-tiles
    // return 'https://api.mapbox.com/v4/mapbox.mapbox-streets-v8/{z}/{x}/{y}.mvt?access_token=$apiKey',
  }
}
```

See the [example](example) for details.

### Widget-based Layer

As an alternative to using `FlutterMap` `layers`, the vector layer can be used as a child widget:

```dart
FlutterMap(
  options: MapOptions(
      center: LatLng(49.246292, -123.116226),
      zoom: 10,
      maxZoom: 15),
  children: [
    VectorTileLayerWidget(
      options: VectorTileLayerOptions(
                  theme: _mapTheme(context),
                  tileProviders: TileProviders(
                      {'openmaptiles': _cachingTileProvider(_urlTemplate())}))
    )
  ]);
```

## Adding Hillshade

A vector tile hillshade layer can be added to your maps by followign these steps:

1. Add hillshade to your theme:

```json
      "sources": {
        "openmaptiles": {"type": "vector", "url": ""},
        "hillshade": {"type": "vector", "url": ""} // add hillshade to sources
      },
      "layers": [
        // background and landcover and water features come here

        // add hillshade to layers right after the water layer and before other features
        {
          "id": "hillshade_faint",
          "type": "fill",
          "source": "hillshade",
          "source-layer": "hillshade",
          "filter": [
            "all",
            ["==", "class", "shadow"],
            ["==", "level", 89]
          ],
          "paint": {"fill-color": "#000", "fill-opacity": 0.02}
        },
        {
          "id": "hillshade_medium",
          "type": "fill",
          "source": "hillshade",
          "source-layer": "hillshade",
          "filter": [
            "all",
            ["==", "class", "shadow"],
            ["==", "level", 78]
          ],
          "paint": {"fill-color": "#000", "fill-opacity": 0.04}
        },
        {
          "id": "hillshade_dark",
          "type": "fill",
          "source": "hillshade",
          "source-layer": "hillshade",
          "filter": [
            "all",
            ["==", "class", "shadow"],
            ["==", "level", 67]
          ],
          "paint": {"fill-color": "#000", "fill-opacity": 0.06}
        },
        {
          "id": "hillshade_extreme",
          "type": "fill",
          "source": "hillshade",
          "source-layer": "hillshade",
          "filter": [
            "all",
            ["==", "class", "shadow"],
            ["==", "level", 56]
          ],
          "paint": {"fill-color": "#000", "fill-opacity": 0.08}
        },
        {
          "id": "hillshade_highlight_medium",
          "type": "fill",
          "source": "hillshade",
          "source-layer": "hillshade",
          "filter": [
            "all",
            ["==", "class", "highlight"],
            ["==", "level", 90]
          ],
          "paint": {"fill-color": "#fff", "fill-opacity": 0.04}
        },
        {
          "id": "hillshade_highlight_bright",
          "type": "fill",
          "source": "hillshade",
          "source-layer": "hillshade",
          "filter": [
            "all",
            ["==", "class", "highlight"],
            ["==", "level", 94]
          ],
          "paint": {"fill-color": "#fff", "fill-opacity": 0.08}
        },

        // other features come here (roads etc.)
      ]
```

2. Add Hillshade Vector Layer to Sources

```dart
  VectorTileLayerOptions(
    theme: _mapTheme(),
    backgroundTheme: _backgroundTheme(),
    renderMode: RenderMode.vector,
    tileProviders: TileProviders({
      'openmaptiles': _cachingTileProvider(_urlTemplate()),
      'hillshade': _cachingTileProvider(_hillshadeUrlTemplate())
    })


    String _hillshadeUrlTemplate() =>
      'https://api.mapbox.com/v4/mapbox.mapbox-terrain-v2/{z}/{x}/{y}.mvt?access_token=$mapboxApiKey';    
```

## Status

This plugin is fairly new and has not yet been broadly used. It's feature complete enough to be a v1, but does
have performance issues on larger screens such as on a tablet or very old devices.

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