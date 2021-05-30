extension ListExtension<T> on List<T> {
  List<T> sorted([int compare(T a, T b)?]) {
    final copy = this.toList();
    copy.sort(compare);
    return copy;
  }
}
