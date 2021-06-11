class ScheduledDebounce {
  final Function() block;
  final Duration delay;
  final Duration maxAge;
  DateTime? last;
  DateTime? start;

  ScheduledDebounce(this.block, this.delay, this.maxAge);

  void update() {
    final first = last == null;
    last = DateTime.now();
    if (first) {
      start = DateTime.now();
      Future.delayed(delay, _check);
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
      _run();
    }
  }

  void _run() {
    last = null;
    start = null;
    block();
  }
}
