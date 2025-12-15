  class BulkResult {
  final bool success;
  final int inserted;
  final int skipped;
  final Map<String, int> skippedReasons;
  final int statusCode;
  BulkResult({required this.statusCode, required this.success, required this.inserted, required this.skipped, required this.skippedReasons});
}