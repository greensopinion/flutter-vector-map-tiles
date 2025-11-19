import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:executor_lib/executor_lib.dart';
import 'package:vector_map_tiles/src/tile_offset.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../tile_translation.dart';
import 'theme_repo.dart';
import 'translation_applier.dart';

class VectorTileTransform {
  final Executor executor;
  final Theme theme;
  final ThemeRepo themeRepo;
  final double tileSize;

  VectorTileTransform({
    required this.executor,
    required this.theme,
    required this.tileSize,
    required this.themeRepo,
  }) {
    themeRepo.initialize(theme, executor);
  }

  Future<Tile> apply(
    Uint8List bytes,
    TileTranslation translation,
    bool Function() cancelled,
    String source,
    TileOffset tileOffset,
  ) async {
    final themeId = theme.id;
    if (!themeRepo.isThemeReady(themeId)) {
      await themeRepo.waitForTheme(themeId);
    }
    final deduplicationKey =
        '${theme.id}-${theme.version}-${translation.original.key()}-${translation.translated.key()}-${translation.xOffset}-${translation.yOffset}';
    final tile = await executor.submit(
      Job(
        deduplicationKey,
        _apply,
        _TransformInput(
            themeId: theme.id,
            tileSize: tileSize,
            bytes: TransferableTypedData.fromList([bytes]),
            translation: translation,
            source: source,
            tileOffset: tileOffset),
        cancelled: cancelled,
        deduplicationKey: deduplicationKey,
      ),
    );
    return tile.materialize();
  }
}

class _TransformInput {
  final String themeId;
  final TransferableTypedData bytes;
  final double tileSize;
  final TileTranslation translation;
  final String source;
  final TileOffset tileOffset;

  _TransformInput({
    required this.themeId,
    required this.bytes,
    required this.tileSize,
    required this.translation,
    required this.source,
    required this.tileOffset,
  });
}

Tile _apply(_TransformInput input) {
  final theme = ThemeRepo.themeById[input.themeId]!;
  final vectorTile =
      VectorTileReader().read(input.bytes.materialize().asUint8List());
  final tileData = TileFactory(
    theme,
    const Logger.noop(),
  ).createTileData(vectorTile);
  final translated = TranslationApplier(
    tileSize: input.tileSize,
  ).apply(tileData, input.translation);

  final tile = translated.toTile();
  final zoom = input.translation.original.z.toDouble();

  final optimized = theme.optimizeTile(tile, zoom);
  optimized.earlyPreRender(
      theme, zoom, input.tileOffset.zoomOffset, input.source);
  return optimized;
}
