class NetworkException implements Exception {
  final String message;

  NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}

class TimeoutException extends NetworkException {
  TimeoutException() : super("Request timed out");
}

class NoConnectionException extends NetworkException {
  NoConnectionException() : super("No internet connection");
}
