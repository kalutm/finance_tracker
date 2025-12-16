class DateRange {
  final DateTime? start;
  final DateTime? end;

  DateRange(this.start, this.end);

  static String? toQueryParam(DateTime? date){
    return date?.toIso8601String();
  }
}