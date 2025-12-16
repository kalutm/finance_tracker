import 'package:finance_frontend/features/transactions/data/model/dtos/date_range.dart';
import 'package:finance_frontend/features/transactions/domain/entities/filter_on_enum.dart';

class StatsIn {
  final FilterOn filterOn;
  final bool onlyExpense;
  final DateRange? range;

  StatsIn({
    this.onlyExpense = true,
    required this.filterOn,
    this.range,
  });
}
