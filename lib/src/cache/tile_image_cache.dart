import 'dart:typed_data';
import 'dart:ui';

import '../tile_identity.dart';
import 'storage_cache.dart';

class TileImageCache {
  final StorageCache _delegate;

  TileImageCache(this._delegate);

  Future<bool> contains(TileIdentity tile, String modifier) async {
    final key = _toKey(tile, modifier);
    return await _delegate.exists(key);
  }

  Future<Image?> retrieve(TileIdentity tile, String modifier) async {
    final key = _toKey(tile, modifier);

    final cached = await _delegate.retrieve(key);
    if (cached != null) {
      final bytes = Uint8List.fromList(cached);
      try {
        final codec = await instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        return frame.image;
      } catch (error, stack) {
        // in case the byte data is invalid, discard and remove the cached value
        print(error);
        print(stack);
        await _removeQuietly(key);
      }
    }
    return null;
  }

  Future<void> _removeQuietly(String key) async {
    try {
      await _remove(key);
    } catch (error, stack) {
      print(error);
      print(stack);
    }
  }

  Future<void> _remove(String key) async {
    await _delegate.remove(key);
  }

  Future<void> put(TileIdentity tile, Image image, String modifier) async {
    final bytes = await image.toByteData(format: ImageByteFormat.png);
    if (bytes == null) {
      throw 'cannot store image';
    }
    final key = _toKey(tile, modifier);
    final cacheData =
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes);
    await _delegate.put(key, cacheData);
  }

  String _toKey(TileIdentity id, String modifier) =>
      '${id.z}_${id.x}_${id.y}_$modifier.png';
}
