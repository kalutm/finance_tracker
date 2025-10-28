import 'package:finance_frontend/features/accounts/domain/entities/account_type_enum.dart';

class AccountPatch {
  final String? name;
  final AccountType? type;
  final String? currency;

  const AccountPatch({this.name, this.type, this.currency});

  bool get isEmpty =>
      name == null && type == null && currency == null;

  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      if (type != null) 'type': type!.name,
      if (currency != null) 'currency': currency,
    };
  }
}
