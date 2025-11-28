import 'package:finance_frontend/features/accounts/domain/entities/account_type_enum.dart';

  Map<String, dynamic> fakeAccountJson({required int id, String? name, AccountType? type, bool active = true}) {
    return {
      'id': id,
      'balance': '50',
      'name': name ?? 'Account$id',
      'type': (type ?? AccountType.BANK).name,
      'currency': 'ETB',
      'active': active,
      'created_at': DateTime.now().toIso8601String(),
    };
  }
