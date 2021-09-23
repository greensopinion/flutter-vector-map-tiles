enum Retryable { retry, none }

class ProviderException implements Exception {
  final Retryable retryable;
  final String message;
  final int? statusCode;

  ProviderException(
      {required this.message, this.statusCode, required this.retryable});

  @override
  String toString() => message;
}
