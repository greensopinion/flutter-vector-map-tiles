import 'package:flutter/material.dart' as material;
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';
// ignore: uri_does_not_exist
import 'api_key.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({material.Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return material.MaterialApp(
      title: 'vector_map_tiles Example',
      theme: material.ThemeData.light(),
      home: const MyHomePage(title: 'vector_map_tiles Example'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return material.Scaffold(
        appBar: material.AppBar(
          title: Text(widget.title),
        ),
        body: SafeArea(
            child: Column(children: [
          Flexible(
              child: FlutterMap(
            options: MapOptions(
                center: LatLng(49.246292, -123.116226),
                zoom: 10,
                maxZoom: 22,
                interactiveFlags: InteractiveFlag.drag |
                    InteractiveFlag.flingAnimation |
                    InteractiveFlag.pinchMove |
                    InteractiveFlag.pinchZoom |
                    InteractiveFlag.doubleTapZoom,
                plugins: [VectorMapTilesPlugin()]),
            layers: <LayerOptions>[
              // normally you would see TileLayerOptions which provides raster tiles
              // instead this vector tile layer replaces the standard tile layer
              VectorTileLayerOptions(
                  theme: _mapTheme(),
                  backgroundTheme: _backgroundTheme(),
                  // tileOffset: TileOffset.mapbox, enable with mapbox
                  tileProviders: TileProviders(
                      // Name must match name under "sources" in theme
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

  Theme _mapTheme() {
    // maps are rendered using themes
    // to provide a dark theme do something like this:
    // if (MediaQuery.of(context).platformBrightness == Brightness.dark) return myDarkTheme();
    return ProvidedThemes.lightTheme();
  }

  _backgroundTheme() {
    return _mapTheme()
        .copyWith(types: {ThemeLayerType.background, ThemeLayerType.fill});
  }

  String _urlTemplate() {
    // IMPORTANT: See readme about matching tile provider with theme

    // Stadia Maps source https://docs.stadiamaps.com/vector/
    // ignore: undefined_identifier
    return 'https://tiles.stadiamaps.com/data/openmaptiles/{z}/{x}/{y}.pbf?api_key=$stadiaMapsApiKey';

    // Mapbox source https://docs.mapbox.com/api/maps/vector-tiles/#example-request-retrieve-vector-tiles
    // return 'https://api.mapbox.com/v4/mapbox.mapbox-streets-v8/{z}/{x}/{y}.mvt?access_token=$mapboxApiKey',
  }
}
