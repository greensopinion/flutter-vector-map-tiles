import 'dart:async';
import 'dart:math';

class ScheduledDebounce {
  final Function() block;
  final Duration delay;
  final Duration jitter;
  final Duration maxAge;
  final Random random = Random();
  DateTime? last;
  DateTime? start;

  ScheduledDebounce(this.block,
      {required this.delay, required this.jitter, required this.maxAge});

  Duration get nextDelay => Duration(
      milliseconds: delay.inMilliseconds +
          (jitter.inMilliseconds == 0
              ? 0
              : random.nextInt(jitter.inMilliseconds)));

  void update() {
    final first = last == null;
    last = DateTime.now();
    if (first) {
      start = DateTime.now();
      Future.delayed(nextDelay, _check);
    } else {
      _checkMaxAge();
    }
  }

  void _check() {
    if (last == null) {
      return;
    }
    final now = DateTime.now();
    final difference =
        now.millisecondsSinceEpoch - last!.millisecondsSinceEpoch;
    final remaining = delay.inMilliseconds - difference;
    if (remaining <= 0) {
      _run();
    } else {
      Future.delayed(Duration(milliseconds: remaining), _check);
    }
  }

  void _checkMaxAge() {
    final elapsed =
        DateTime.now().millisecondsSinceEpoch - start!.millisecondsSinceEpoch;
    if (elapsed >= maxAge.inMilliseconds) {
      scheduleMicrotask(_run);
    }
  }

  void _run() {
    last = null;
    start = null;
    block();
  }
}
