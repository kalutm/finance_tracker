  import 'package:finance_frontend/features/transactions/domain/entities/transaction_type.dart';

Map<String, dynamic> fakeTransactionJson({required int id, int accountId = 1, TransactionType? type, String? transferGroupId, bool? isOutGoing}) {
    return {
      'id': id,
      'amount': '50',
      'is_outgoing': isOutGoing,
      'account_id': accountId,
      'category_id': 1,
      'currency': "ETB",
      'merchant': "Queen's",
      'type': (type ?? TransactionType.EXPENSE).name,
      'description': "test transaction",
      'transfer_group_id': transferGroupId,
      'created_at': DateTime.now().toIso8601String(),
      'occurred_at': DateTime.now().toIso8601String(),
    };
  }
