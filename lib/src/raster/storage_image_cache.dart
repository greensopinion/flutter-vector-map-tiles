import 'dart:typed_data';
import 'dart:ui';

import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../../vector_map_tiles.dart';
import '../cache/storage_cache.dart';

class StorageImageCache {
  late final String themeKey;
  final StorageCache delegate;

  StorageImageCache(Theme theme, this.delegate) {
    themeKey = '${theme.id}-v${theme.version}'
        .replaceAll(RegExp(r'[^a-zA-Z0-9.-]'), '-');
  }

  Future<Image?> retrieve(TileIdentity tile) async {
    String key = _key(tile);
    final cached = await delegate.retrieve(key);
    if (cached != null) {
      final bytes = Uint8List.fromList(cached);
      try {
        final codec = await instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        return frame.image;
      } catch (error, stack) {
        // in case the byte data is invalid, discard and remove the cached value
        // ignore: avoid_print
        print(error);
        // ignore: avoid_print
        print(stack);
        await _removeQuietly(key);
      }
    }
    return null;
  }

  Future<void> put(TileIdentity tile, Image image) async {
    final bytes = await image.toByteData(format: ImageByteFormat.png);
    if (bytes != null) {
      await delegate.put(_key(tile), bytes.buffer.asUint8List());
    }
  }

  String _key(TileIdentity tile) {
    return '$themeKey-${tile.z}-${tile.x}-${tile.y}.png';
  }

  Future _removeQuietly(String key) async {
    try {
      delegate.remove(key);
    } catch (_) {}
  }
}
