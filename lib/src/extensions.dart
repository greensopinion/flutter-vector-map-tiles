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
