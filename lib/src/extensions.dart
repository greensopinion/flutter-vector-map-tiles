import 'package:flutter/foundation.dart';
import 'package:executor_lib/executor_lib.dart';

extension ListExtension<T> on List<T> {
  List<T> sorted([int Function(T a, T b)? compare]) {
    final copy = toList();
    copy.sort(compare);
    return copy;
  }
}

extension IterableExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

extension CancellationFutureWithDebug<T> on Future<T> {
  /// Schluckt CancellationException und loggt den Call Stack im Debug Mode
  Future<T?> swallowCancellationWithDebug() async {
    try {
      return await this;
    } catch (error, st) {
      if (error is CancellationException) {
        if (kDebugMode) {
          debugPrint('❌ CancellationException: $error');
          debugPrintStack(stackTrace: st);
        }
        return null;
      }
      rethrow;
    }
  }
}
