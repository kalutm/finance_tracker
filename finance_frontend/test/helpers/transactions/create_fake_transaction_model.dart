import 'package:finance_frontend/features/transactions/data/model/transaction_model.dart';
import 'package:finance_frontend/features/transactions/domain/entities/transaction_type.dart';

TransactionModel fakeTransactionModel({
  required String id,
  String? accountId,
  TransactionType? type,
  String? amount,
  bool? isOutGoing,
  String? transferGroupId,
}) {
  return TransactionModel(
    id: id,
    amount: amount??"50",
    isOutGoing: isOutGoing,
    accountId: accountId ?? "1",
    currency: "ETB",
    type: type ?? TransactionType.EXPENSE,
    transferGroupId: transferGroupId,
    createdAt: DateTime.now().toIso8601String(),
    occuredAt: DateTime.now().toIso8601String(),
  );
}
