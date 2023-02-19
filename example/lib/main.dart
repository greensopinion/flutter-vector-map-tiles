import 'package:flutter/material.dart' hide Theme;
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
  const MyApp({Key? key}) : super(key: key);

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
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
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
      children.add(Flexible(child: _map()));
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

  Future<Style> _readStyle() => StyleReader(
          uri: 'https://api.maptiler.com/maps/streets-v2/style.json?key={key}',
          apiKey: maptilerApiKey,
          logger: const Logger.console())
      .read();

  Widget _map() => FlutterMap(
        mapController: _controller,
        options: MapOptions(
            center: _style!.center ?? LatLng(49.246292, -123.116226),
            zoom: _style!.zoom ?? 10,
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
              theme: _style!.theme,
              backgroundTheme: _style!.theme.copyWith(
                  types: {ThemeLayerType.background, ThemeLayerType.fill}),
              // tileOffset: TileOffset.mapbox, enable with mapbox
              tileProviders: _style!.providers),
        ],
      );

  Widget _statusText() => Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: StreamBuilder(
          stream: _controller.mapEventStream,
          builder: (context, snapshot) {
            return Text(
                'Zoom: ${_controller.zoom.toStringAsFixed(2)} Center: ${_controller.center.latitude.toStringAsFixed(4)},${_controller.center.longitude.toStringAsFixed(4)}');
          }));
}
