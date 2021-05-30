import 'package:flutter/widgets.dart';

abstract class DisposableState<T extends StatefulWidget> extends State<T> {
  bool _disposed = false;
  bool get disposed => _disposed;

  @override
  void dispose() {
    super.dispose();
    _disposed = true;
  }
}
