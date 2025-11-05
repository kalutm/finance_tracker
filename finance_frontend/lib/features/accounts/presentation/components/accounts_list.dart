import 'package:finance_frontend/features/accounts/data/services/finance_account_service.dart';
import 'package:finance_frontend/features/accounts/domain/entities/account.dart';
import 'package:finance_frontend/features/accounts/presentation/blocs/account_form/account_form_bloc.dart';
import 'package:finance_frontend/features/accounts/presentation/blocs/accounts/accounts_bloc.dart';
import 'package:finance_frontend/features/accounts/presentation/views/create_update_account_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AccountsList extends StatelessWidget {
  final List<Account> accounts;
  const AccountsList({super.key, required this.accounts});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: accounts.length,
      itemBuilder: (context, index) {
        final account = accounts[index];
        return ListTile(
          leading: Text(account.active ? "active" : "deleted"),
          title: Text(account.name),
          subtitle: Text(account.balance),
          trailing: Text(account.type.name),
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => BlocProvider.value(
                        value: context.read<AccountsBloc>(),
                        child: BlocProvider<AccountFormBloc>(
                          create:
                              (context) =>
                                  AccountFormBloc(FinanceAccountService()),
                          child: CreateUpdateAccountView(
                            isUpdate: true,
                            account: account,
                          ),
                        ),
                      ),
                ),
              ),
        );
      },
    );
  }
}
