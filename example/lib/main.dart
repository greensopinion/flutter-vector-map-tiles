import 'package:flutter/material.dart' as material;
import 'package:flutter/widgets.dart';
import 'package:vector_map_tiles_example/map.dart';

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
        body:
            SafeArea(child: Column(children: [Flexible(child: MapWidget())])));
  }
}
