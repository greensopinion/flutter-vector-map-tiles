import 'dart:async';

import 'package:executor_lib/executor_lib.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';


class ThemeRepo {
  final _completers = <String, Completer<void>>{};
  static final themeById = <String, Theme>{};

  Future<void> waitForTheme(String themeId) {
    return _completers[themeId]?.future ?? Future.value();
  }

  bool isThemeReady(String themeId) {
    return _completers[themeId]?.isCompleted ?? false;
  }

  Future<void> initialize(Theme theme, Executor executor) async {
    final themeId = theme.id;
    if (_completers[themeId]?.isCompleted == true) {
      return;
    } else {
      final completer = _completers[themeId];
      if (completer != null) {
        return completer.future;
      }
    }

    _completers[themeId] ??= Completer<void>();

    final futures = executor.submitAll(
      Job(
        'setupTheme',
        _setupTheme,
        theme,
        deduplicationKey:
        'VectorTileTransform-setup-theme-${theme.id}-${theme.version}',
      ),
    );
    for (final future in futures) {
      await future;
    }
    if (!_completers[themeId]!.isCompleted) {
      _completers[themeId]!.complete();
    }
  }

  static Future<void> _setupTheme(Theme theme) async {
    themeById[theme.id] = theme;
  }
}