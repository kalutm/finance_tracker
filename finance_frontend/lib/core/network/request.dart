class RequestModel {
  final String method; // 'GET', 'POST', ...
  final Uri url;
  final Map<String, String>? headers;
  final dynamic body;

  RequestModel({
    required this.method,
    required this.url,
    this.headers,
    this.body,
  });
}
