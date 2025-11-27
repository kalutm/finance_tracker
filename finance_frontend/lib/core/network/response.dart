class ResponseModel {
  final int statusCode;
  final Map<String, String> headers;
  final String body;

  ResponseModel({
    required this.statusCode,
    required this.headers,
    required this.body,
  });

  bool get isSuccessful => statusCode >= 200 && statusCode < 300;
}
