# [vector_map_tiles](https://pub.dev/packages/vector_map_tiles)

A plugin for [`flutter_map`](https://pub.dev/packages/flutter_map) that enables the use of vector tiles with slippy maps and Flutter.

Loads vector tiles from a source such as Mapbox or Stadia Maps, and renders them as a layer on a `flutter_map`.

Tile rendering can be vector, mixed, or raster. Mixed mode is default, since that provides an optimal trade-off between sharp visuals when idle, and smooth animation when zooming with a pinch gesture.

<img src="https://raw.githubusercontent.com/greensopinion/flutter-vector-map-tiles/main/vector_map_tiles-example.png" alt="example screenshot" width="292"/> <img src="https://raw.githubusercontent.com/greensopinion/flutter-vector-map-tiles/main/vector_map_tiles-example-hillshade.png" alt="example screenshot" width="292"/>

See the [gallery](gallery/gallery.md) for more examples.

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

A vector tile hillshade layer can be added to your maps by following these steps:

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