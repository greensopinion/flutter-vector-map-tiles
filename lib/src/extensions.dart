import 'package:flutter_map/flutter_map.dart';

import 'tile_identity.dart';

extension ListExtension<T> on List<T> {
  List<T> sorted([int Function(T a, T b)? compare]) {
    final copy = toList();
    copy.sort(compare);
    return copy;
  }
}

extension IterableExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

extension TileIdExtension on TileCoordinates {
  TileIdentity toTileIdentity() => TileIdentity(z, x, y);
}
