import 'dart:typed_data';
import 'dart:ui';

import 'memory_cache.dart';
import 'storage_cache.dart';
import '../tile_identity.dart';

class TileImageCache {
  final StorageCache _delegate;
  final MemoryCache memoryCache = MemoryCache(maxSizeBytes: 10 * 1024 * 1024);

  TileImageCache(this._delegate);

  Future<Image?> retrieve(TileIdentity tile, String modifier) async {
    final key = _toKey(tile, modifier);
    var bytes = memoryCache.getItem(key);
    if (bytes == null) {
      final cached = await _delegate.retrieve(key);
      if (cached != null) {
        bytes = Uint8List.fromList(cached);
      }
    }
    if (bytes != null) {
      final codec = await instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      return frame.image;
    }
  }

  Future<void> put(TileIdentity tile, Image image, String modifier) async {
    final bytes = await image.toByteData(format: ImageByteFormat.png);
    if (bytes == null) {
      throw 'cannot store image';
    }
    final key = _toKey(tile, modifier);
    final cacheData =
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes);
    memoryCache.putItem(key, cacheData);
    await _delegate.put(key, cacheData);
  }

  String _toKey(TileIdentity id, String modifier) =>
      '${id.z}_${id.x}_${id.y}_$modifier.png';
}
