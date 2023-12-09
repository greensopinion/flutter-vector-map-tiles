import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as material show Theme;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart' hide TileLayer;
// ignore: uri_does_not_exist
import 'api_key.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'vector_map_tiles Example',
      theme: ThemeData.light(),
      home: const MyHomePage(title: 'vector_map_tiles Example'),
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
  final MapController _controller = MapController();
  Style? _style;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _initStyle();
  }

  void _initStyle() async {
    try {
      _style = await _readStyle();
    } catch (e, stack) {
      // ignore: avoid_print
      print(e);
      // ignore: avoid_print
      print(stack);
      _error = e;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    if (_error != null) {
      children.add(Expanded(child: Text(_error!.toString())));
    } else if (_style == null) {
      children.add(const Center(child: CircularProgressIndicator()));
    } else {
      children.add(Flexible(child: _map(_style!)));
      children.add(Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [_statusText()]));
    }
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: SafeArea(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: children)));
  }

// alternates:
//   Mapbox - mapbox://styles/mapbox/streets-v12?access_token={key}
//   Maptiler - https://api.maptiler.com/maps/outdoor/style.json?key={key}
//   Stadia Maps - https://tiles.stadiamaps.com/styles/outdoors.json?api_key={key}
  Future<Style> _readStyle() => StyleReader(
          uri: 'mapbox://styles/mapbox/streets-v12?access_token={key}',
          // ignore: undefined_identifier
          apiKey: mapboxApiKey,
          logger: const Logger.console())
      .read();

  Widget _map(Style style) => FlutterMap(
        mapController: _controller,
        options: MapOptions(
            initialCenter: style.center ?? const LatLng(49.246292, -123.116226),
            initialZoom: style.zoom ?? 10,
            maxZoom: 22,
            backgroundColor: material.Theme.of(context).canvasColor),
        children: [
          VectorTileLayer(
              tileProviders: style.providers,
              theme: style.theme,
              sprites: style.sprites,
              maximumZoom: 22,
              tileOffset: TileOffset.mapbox,
              layerMode: VectorTileLayerMode.vector)
        ],
      );

  Widget _statusText() => Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: StreamBuilder(
          stream: _controller.mapEventStream,
          builder: (context, snapshot) {
            return Text(
                'Zoom: ${_controller.camera.zoom.toStringAsFixed(2)} Center: ${_controller.camera.center.latitude.toStringAsFixed(4)},${_controller.camera.center.longitude.toStringAsFixed(4)}');
          }));
}
