import 'package:finance_frontend/features/accounts/domain/entities/account_type_enum.dart';
import 'package:finance_frontend/features/accounts/domain/entities/dtos/account_create.dart';

AccountCreate fakeAccountCreate({String name = "CBE"}) {
  return AccountCreate(name: name, type: AccountType.BANK, currency: "ETB");
}
