import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:vector_map_tiles_example/map_info.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart'
    hide TileLayer, Theme;

// ignore: uri_does_not_exist
import 'local_api_key.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vector Map Tiles Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Vector Map Tiles Example'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Style? style;

  @override
  void initState() {
    super.initState();

    StyleReader(
      uri: 'mapbox://styles/mapbox/streets-v12?access_token={key}',
      // ignore: undefined_identifier
      apiKey: mapboxApiKey,
      logger: const Logger.console(),
    ).read().then((style) {
      this.style = style;
      setState(() {});
    });
  }

  final options = const MapOptions(
    initialCenter: LatLng(49.246292, -123.116226),
    initialZoom: 12.5,
    maxZoom: 18.0,
  );

  @override
  Widget build(BuildContext context) {
    Widget body;

    if (style != null) {
      body = FlutterMap(
        options: options,
        children: [
          SizedBox.expand(
            child: VectorTileLayer(
              tileProviders: style!.providers,
              theme: style!.theme,
              sprites: style!.sprites,
              tileOffset: TileOffset.mapbox,
            ),
          ),
          const MapInfo(),
        ],
      );
    } else {
      body = const SizedBox.expand(
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: body,
    );
  }
}
