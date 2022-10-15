import 'package:executor_lib/executor_lib.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../tile_model.dart';
import 'delay_painter.dart';
import 'tile_options.dart';

class SymbolsDelayPainterModel extends DelayPainterModel {
  SymbolsDelayPainterModel(VectorTileModel model)
      : super(key: model.tile.key(), show: () => model.showLabels) {
    model.addListener(notifyUpdate);
    model.symbolState.addListener(notifyReady);
  }
}

class UpdateTileLabelsJob {
  final VectorTileOptions _options;
  final CreatedTextPainterProvider _painterProvider;

  UpdateTileLabelsJob(this._options, this._painterProvider);

  Job toExecutorJob() {
    return Job('labels ${_options.model.tile}', _updateLabels, this,
        deduplicationKey: null, cancelled: () => _options.model.disposed);
  }

  void updateLabels() {
    if (!_options.model.disposed) {
      final remainingSymbols = _painterProvider.symbolsWithoutPainter();
      if (remainingSymbols.isEmpty) {
        _options.symbolsDelayPainterModel?.notifyReady();
      } else {
        final symbol = remainingSymbols.first;
        final painter = _painterProvider.create(symbol);
        _options.textCache.put(symbol, painter);
        Future.delayed(const Duration(milliseconds: 2)).then((value) =>
            _labelUpdateExecutor.submit(toExecutorJob()).swallowCancellation());
      }
    }
  }
}

bool _updateLabels(job) {
  (job as UpdateTileLabelsJob).updateLabels();
  return true;
}

final _labelUpdateExecutor = QueueExecutor();

void sheduleLabelsUpdate(VectorTileOptions options,
        CreatedTextPainterProvider painterProvider) =>
    _labelUpdateExecutor
        .submit(UpdateTileLabelsJob(options, painterProvider).toExecutorJob())
        .swallowCancellation();
