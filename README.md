# [vector_map_tiles](https://pub.dev/packages/vector_map_tiles)

A plugin for [`flutter_map`](https://pub.dev/packages/flutter_map) that enables the use of vector tiles with slippy maps and Flutter.

Loads vector tiles from a source such as Mapbox or Stadia Maps, and renders them as a layer on a `flutter_map`.

Tile rendering can be vector, mixed, or raster. Mixed mode is default, since that provides an optimal trade-off between sharp visuals when idle, and smooth animation when zooming with a pinch gesture.

<img src="https://raw.githubusercontent.com/greensopinion/flutter-vector-map-tiles/main/vector_map_tiles-example.png" alt="example screenshot" width="292"/>


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
                interactiveFlags: InteractiveFlag.doubleTapZoom |
                    InteractiveFlag.drag |
                    InteractiveFlag.pinchZoom |
                    InteractiveFlag.pinchMove,
                plugins: [VectorMapTilesPlugin()]),
            layers: <LayerOptions>[
              // normally you would see TileLayerOptions which provides raster tiles
              // instead this vector tile layer replaces the standard tile layer
              VectorTileLayerOptions(
                  theme: _mapTheme(context),
                  tileProvider: MemoryCacheVectorTileProvider(
                      delegate: NetworkVectorTileProvider(
                          urlTemplate: _urlTemplate(),
                          // this is the maximum zoom of the provider, not the
                          // maximum of the map. vector tiles are rendered
                          // to larger sizes to support higher zoom levels
                          maximumZoom: 14),
                      maxSizeBytes: 1024 * 1024 * 2)),
            ],
          ))
        ])));
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

## Status

This plugin is fairly new and has not yet been broadly used. It's feature complete enough to be a v1, but does
have performance issues on larger screens such as on a tablet or very old devices.

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