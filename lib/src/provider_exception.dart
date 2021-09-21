enum Retryable { retry, none }

class ProviderException implements Exception {
  final Retryable retryable;
  final String message;

  ProviderException({required this.message, required this.retryable});

  @override
  String toString() => message;
}
