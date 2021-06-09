import 'dart:typed_data';
import 'dart:ui';

import 'storage_cache.dart';
import '../tile_identity.dart';

class TileImageCache {
  final StorageCache _delegate;

  TileImageCache(this._delegate);

  Future<Image?> retrieve(TileIdentity tile, String modifier) async {
    final bytes = await _delegate.retrieve(_toKey(tile, modifier));
    if (bytes != null) {
      final imageData = Uint8List.fromList(bytes);
      final codec = await instantiateImageCodec(imageData);
      final frame = await codec.getNextFrame();
      return frame.image;
    }
  }

  Future<void> put(TileIdentity tile, Image image, String modifier) async {
    final bytes = await image.toByteData(format: ImageByteFormat.png);
    if (bytes == null) {
      throw 'cannot store image';
    }
    await _delegate.put(_toKey(tile, modifier),
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes));
  }

  String _toKey(TileIdentity id, String modifier) =>
      '${id.z}_${id.x}_${id.y}_$modifier.png';
}
