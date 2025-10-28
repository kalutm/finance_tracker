import 'package:finance_frontend/features/accounts/domain/entities/account_type_enum.dart';
import 'package:decimal/decimal.dart';

class Account {
  final String id;
  final String balance;
  final String name;
  final AccountType type;
  final String currency;
  final bool active;
  final DateTime createdAt;

  Decimal get balanceValue => Decimal.parse(balance);

  Account({
    required this.id,
    required this.balance,
    required this.name,
    required this.type,
    required this.currency,
    required this.active,
    required this.createdAt,
  });

  factory Account.fromFinance(Map<String, dynamic> json) {
    return Account(
      id: json['id'] as String,
      balance: json['balance'] as String,
      name: json['name'] as String,
      type: AccountType.values.byName(json['type'] as String),
      currency: json['currency'] as String,
      active: json['active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toFinance() {
    return {
      'id': id,
      'balance': balance,
      'name': name,
      'type': type.name,
      'currency': currency,
      'active': active,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
