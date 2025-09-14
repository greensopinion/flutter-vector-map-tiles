import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:executor_lib/executor_lib.dart';
import 'package:vector_map_tiles/src/loader/theme_repo.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../tile_translation.dart';
import 'translation_applier.dart';

class VectorTileTransform {
  final Executor executor;
  final Theme theme;
  final double tileSize;

  VectorTileTransform({
    required this.executor,
    required this.theme,
    required this.tileSize,
  }) {
    ThemeRepo.initialize(theme, executor);
  }

  Future<Tile> apply(
    Uint8List bytes,
    TileTranslation translation,
    bool Function() cancelled,
  ) async {
    final themeId = theme.id;
    if (!ThemeRepo.isThemeReady(themeId)) {
      await ThemeRepo.waitForTheme(themeId);
    }
    final deduplicationKey =
        '${theme.id}-${theme.version}-${translation.original.key()}-${translation.translated.key()}-${translation.xOffset}-${translation.yOffset}';
    return await executor.submit(
      Job(
        deduplicationKey,
        _apply,
        _TransformInput(
          themeId: theme.id,
          tileSize: tileSize,
          bytes: TransferableTypedData.fromList([bytes]),
          translation: translation,
        ),
        cancelled: cancelled,
        deduplicationKey: deduplicationKey,
      ),
    );
  }
}

class _TransformInput {
  final String themeId;
  final TransferableTypedData bytes;
  final double tileSize;
  final TileTranslation translation;

  _TransformInput({
    required this.themeId,
    required this.bytes,
    required this.tileSize,
    required this.translation,
  });
}

Tile _apply(_TransformInput input) {
  final theme = ThemeRepo.themeById[input.themeId]!;
  final vectorTile = VectorTileReader().read(input.bytes.materialize().asUint8List());
  final tileData = TileFactory(
    theme,
    const Logger.noop(),
  ).createTileData(vectorTile);
  final translated = TranslationApplier(
    tileSize: input.tileSize,
  ).apply(tileData, input.translation);
  return translated.toTile();
}


