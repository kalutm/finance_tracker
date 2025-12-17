import 'package:decimal/decimal.dart';

class AccountBalance {
  final int id;
  final String name;
  final String balance;

  AccountBalance({required this.id, required this.name, required this.balance});

  Decimal get balanceValue => Decimal.parse(balance);

  factory AccountBalance.fromJson(Map<String, dynamic> json) {
    return AccountBalance(
      id: json['id'] as int,
      name: json['name'] as String,
      balance: json['balance'] as String,
    );
  }
}
