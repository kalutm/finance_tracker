import 'package:finance_frontend/features/transactions/domain/exceptions/transaction_exceptions.dart';

class TransactionErrorScenario{
  final int statusCode;
  final String code;
  final Type expectedException;

  TransactionErrorScenario({
    required this.statusCode,
    required this.code,
    required this.expectedException,
  });
}