extension FileSafeString on String {
  String fileSafe() => replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '-');
}
