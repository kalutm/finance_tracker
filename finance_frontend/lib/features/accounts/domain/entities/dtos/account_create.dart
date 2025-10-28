import 'package:finance_frontend/features/accounts/domain/entities/account_type_enum.dart';

class AccountCreate {
  final String name;
  final AccountType type;
  final String currency;

  const AccountCreate({
    required this.name,
    required this.type,
    required this.currency,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type.name,
      'currency': currency,
    };
  }
}
