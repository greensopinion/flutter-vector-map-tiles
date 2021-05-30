import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart' as renderer;
import 'api_key.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vector Tiles Demo',
      theme: ThemeData.light(),
      home: MyHomePage(title: 'Vector Tiles Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final theme = renderer.ThemeReader().read(renderer.lightTheme());
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
                plugins: [VectorMapTilesPlugin()]),
            layers: <LayerOptions>[
              // TileLayerOptions(
              //     urlTemplate:
              //         'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              //     subdomains: ['a', 'b', 'c'],
              //     // For example purposes. It is recommended to use
              //     // TileProvider with a caching and retry strategy, like
              //     // NetworkTileProvider or CachedNetworkTileProvider
              //     tileProvider: NonCachingNetworkTileProvider()),
              VectorTileLayerOptions(
                  theme: theme,
                  tileProvider: MemoryCacheVectorTileProvider(
                      delegate: NetworkVectorTileProvider(
                        urlTemplate:
                            'https://tiles.stadiamaps.com/data/openmaptiles/{z}/{x}/{y}.pbf?api_key=$apiKey',
                      ),
                      maxSizeBytes: 1024 * 1024 * 2)),
            ],
          ))
        ])));
  }
}
