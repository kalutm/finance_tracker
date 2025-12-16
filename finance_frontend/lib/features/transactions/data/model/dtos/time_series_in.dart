import 'package:finance_frontend/features/transactions/data/model/dtos/date_range.dart';
import 'package:finance_frontend/features/transactions/domain/entities/granulity_enum.dart';

class TimeSeriesIn {
  final Granulity granulity;
  final DateRange range;

  TimeSeriesIn({required this.granulity, required this.range});
}