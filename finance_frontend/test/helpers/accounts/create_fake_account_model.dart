import 'package:finance_frontend/features/accounts/domain/entities/account.dart';
import 'package:finance_frontend/features/accounts/domain/entities/account_type_enum.dart';

Account createFakeAccount({
  required String id,
  String? name,
  AccountType? type,
  bool active = true,
}) {
  return Account(
    id: id,
    balance: "50",
    name: name ?? "Account $id",
    type: type ?? AccountType.BANK,
    currency: "ETB",
    active: active,
    createdAt: DateTime.now(),
  );
}
