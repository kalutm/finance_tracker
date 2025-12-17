import 'package:finance_frontend/features/transactions/data/model/dtos/date_range.dart';
import 'package:finance_frontend/features/transactions/domain/entities/transaction_type.dart';

class ListTransactionsIn {
  final DateRange? range;
  final String? accountId;
  final String? categoryId;
  final TransactionType? type;
  final int? page;
  final int? perPage;

  ListTransactionsIn({
    this.range,
    this.accountId,
    this.categoryId,
    this.type,
    this.page,
    this.perPage,
  });
}
