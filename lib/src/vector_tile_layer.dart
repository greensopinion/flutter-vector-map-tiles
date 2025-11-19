import 'dart:io';

import 'package:flutter/material.dart' hide Theme;
import 'package:vector_map_tiles/src/style/style.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import 'cache/cache.dart';
import 'model/map_properties.dart';
import 'tile_offset.dart';
import 'tile_providers.dart';
import 'widgets/map_layer.dart';
import 'widgets/map_tiles_layer.dart';

/// A widget for a vector tile layer, to be used as a child
/// of a [FlutterMap].
/// See readme for details.
class VectorTileLayer extends StatelessWidget {
  /// provides vector tiles, by source ID where the source ID corresponds to
  /// a source in the theme
  final TileProviders tileProviders;

  /// the theme used to render tiles
  final Theme theme;

  final SpriteStyle? sprites;

  /// the tile offset
  final TileOffset tileOffset;

  /// The level of concurrency to use, must be >= 0.
  /// When set to 1 or higher, [isolates](https://dart.dev/guides/language/concurrency)
  /// are used for computations to offload expensive operations from the UI thread.
  /// This setting has no effect in debug mode.
  final int concurrency;

  /// The default [concurrency]
  static const defaultConcurrency = 4;

  /// the maximum size of the file-based cache in bytes.
  /// the cache does a good-enough effort to keep the cache size
  /// within the specified limit, however the size can exceed the
  /// specified limit from time to time.
  final int fileCacheMaximumSizeInBytes;

  /// the default [fileCacheMaximumSizeInBytes]
  static const defaultCacheMaxSize = 50 * 1024 * 1024;

  /// the time to live of items in the file cache
  /// consider the terms of your tile provider service
  /// and the desired freshness of map data when setting this value
  final Duration fileCacheTtl;

  /// the default [fileCacheTtl]
  static const defaultCacheTtl = Duration(days: 30);

  /// A function that resolves a folder for filesystem caching.
  /// If unspecified, defaults to a subfolder of the temporary directory.
  /// Applications that wish to delete persistent cache data should specify
  /// this function.
  final Future<Directory> Function()? cacheFolder;

  const VectorTileLayer({
    super.key,
    required this.tileProviders,
    required this.theme,
    required this.tileOffset,
    this.concurrency = defaultConcurrency,
    this.fileCacheTtl = defaultCacheTtl,
    this.fileCacheMaximumSizeInBytes = defaultCacheMaxSize,
    this.cacheFolder,
    this.sprites,
  });

  @override
  Widget build(BuildContext context) =>
      SizedBox.expand(child: _buildGpu(context));

  Widget _buildGpu(BuildContext context) => MapLayer(
        key: Key('map_layer_${theme.id}_${theme.version}'),
        mapProperties: _createMapProperties(),
      );

  // ignore: unused_element
  Widget _buildCanvas(BuildContext context) => MapTilesLayer(
        key: Key('map_tiles_${theme.id}_${theme.version}'),
        mapProperties: _createMapProperties(),
      );

  MapProperties _createMapProperties() => MapProperties(
        tileProviders: tileProviders,
        theme: theme,
        sprites: sprites,
        tileOffset: tileOffset,
        concurrency: concurrency,
        cacheProperties: CacheProperties(
          fileCacheTtl: fileCacheTtl,
          fileCacheMaximumSizeInBytes: fileCacheMaximumSizeInBytes,
          cacheFolder: cacheFolder,
        ),
      );
}
