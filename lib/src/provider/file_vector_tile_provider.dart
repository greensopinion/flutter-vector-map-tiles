import 'dart:io';
import 'dart:typed_data';

import '../../vector_map_tiles.dart';

/// provides tiles from a filesystem folder.
/// tiles are expected to be organized by `root/z/x/y.extension`
///
class FileVectorTileProvider extends VectorTileProvider {
  @override
  final TileProviderType type;

  /// the file extension of files to load, e.g. png or pbf
  final String extension;

  /// The path to the root folder of the tiles.
  /// May be absolute or relative.
  final String root;

  @override
  final int maximumZoom;

  @override
  final int minimumZoom;
  @override
  final TileOffset tileOffset;

  FileVectorTileProvider(
      {required this.root,
      required this.extension,
      required this.type,
      this.tileOffset = TileOffset.DEFAULT,
      required this.maximumZoom,
      required this.minimumZoom});

  @override
  Future<Uint8List> provide(TileIdentity tile) async {
    File file = File('$root/${tile.z}/${tile.x}/${tile.y}.$extension');
    try {
      return await file.readAsBytes();
    } catch (e) {
      throw ProviderException(
          message: "$e", retryable: Retryable.none, statusCode: 404);
    }
  }
}
