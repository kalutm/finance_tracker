import 'package:finance_frontend/features/transactions/data/model/account_balance.dart';

class AccountBalances {
  final String totalBalance;
  final List<AccountBalance> accounts;

  AccountBalances({required this.totalBalance, required this.accounts});

  static List<AccountBalance> accountsFromJson(List<Map<String, dynamic>> json){
    return json.map((a) => AccountBalance.fromJson(a)).toList();
  }
}