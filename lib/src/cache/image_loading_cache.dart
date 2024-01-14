import 'dart:typed_data';
import 'dart:ui';

import '../../vector_map_tiles.dart';
import 'storage_cache.dart';

class ImageLoadingCache {
  final StorageCache delegate;
  final TileProviders providers;
  final keyToFuture = <String, Future<Uint8List>>{};

  ImageLoadingCache({required this.delegate, required this.providers});

  /// caller is responsible for disposing the image
  Future<Image> retrieve(String source, TileIdentity tile) async {
    final key = _toKey(source, tile);
    var cached = true;
    var bytes = await delegate.retrieve(key);
    if (bytes == null) {
      cached = false;
      final provider = providers.get(source);
      if (provider.type != TileProviderType.raster) {
        throw '$source is not a raster provider';
      }
      bytes = await keyToFuture.putIfAbsent(
          key, () => providers.get(source).provide(tile));
    }
    try {
      final codec = await instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      if (!cached) {
        await _putQuietly(key, image);
        keyToFuture.remove(key);
      }
      return image;
    } catch (_) {
      await _removeQuietly(key);
      keyToFuture.remove(key);
      rethrow;
    }
  }

  String _toKey(String source, TileIdentity id) =>
      '${id.z}_${id.x}_${id.y}_$source.png';

  Future _putQuietly(String key, Image image) async {
    Image cloned = image.clone();
    try {
      final bytes = await cloned.toByteData(format: ImageByteFormat.png);
      if (bytes != null) {
        await delegate.put(key, bytes.buffer.asUint8List());
      }
    } catch (_) {
      // nothing to do
    } finally {
      cloned.dispose();
    }
  }

  Future _removeQuietly(String key) async {
    try {
      await delegate.remove(key);
    } catch (_) {}
  }
}
