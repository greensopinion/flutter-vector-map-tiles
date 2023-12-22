import 'dart:ui';

import 'package:flutter/painting.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../vector_map_tiles.dart';
import 'future_tile_provider.dart';
import 'tile_protocol.dart';
import 'tile_server.dart';

TileProvider createTileProvider(
    {required String styleUri,
    String? styleApiKey,
    TileOffset tileOffset = TileOffset.DEFAULT}) {
  return _RoundRobinTileProvider(delegates: [
    _createServerTileProvider(
        styleUri: styleUri, styleApiKey: styleApiKey, tileOffset: tileOffset),
    _createServerTileProvider(
        styleUri: styleUri, styleApiKey: styleApiKey, tileOffset: tileOffset),
    _createServerTileProvider(
        styleUri: styleUri, styleApiKey: styleApiKey, tileOffset: tileOffset),
  ]);
}

TileProvider _createServerTileProvider(
    {required String styleUri,
    String? styleApiKey,
    TileOffset tileOffset = TileOffset.DEFAULT}) {
  final server = TileServer();
  server.send(LoadStyleFromUriRequest(
      requestId: newTileProtoRequestId(),
      uri: styleUri,
      apiKey: styleApiKey,
      tileOffset: tileOffset.zoomOffset));
  return FutureTileProvider(
      loader: (coords, options, cancelled) async {
        final response = (await server.send(TileRequest(
            requestId: newTileProtoRequestId(),
            x: coords.x,
            y: coords.y,
            z: coords.z))) as TileResponse;
        if (response.success) {
          final codec = await instantiateImageCodec(response.tileData!);
          final frame = await codec.getNextFrame();
          return ImageInfo(image: frame.image, scale: 2.0);
        } else {
          // ignore: avoid_print
          print(response.errorMessage);
          // ignore: avoid_print
          print(response.stack);
          throw Exception(response.errorMessage);
        }
      },
      disposer: server.dispose);
}

class _RoundRobinTileProvider extends TileProvider {
  final List<TileProvider> delegates;
  var index = 0;

  _RoundRobinTileProvider({required this.delegates});

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    ++index;
    return delegates[index % delegates.length].getImage(coordinates, options);
  }

  @override
  void dispose() {
    super.dispose();
    for (final delegate in delegates) {
      delegate.dispose();
    }
  }
}
