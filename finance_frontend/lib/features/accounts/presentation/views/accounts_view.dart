import 'package:finance_frontend/features/accounts/data/services/finance_account_service.dart';
import 'package:finance_frontend/features/accounts/presentation/blocs/account_form/account_form_bloc.dart';
import 'package:finance_frontend/features/accounts/presentation/blocs/accounts/accounts_bloc.dart';
import 'package:finance_frontend/features/accounts/presentation/blocs/accounts/accounts_state.dart';
import 'package:finance_frontend/features/accounts/presentation/views/create_update_account_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AccountsView extends StatefulWidget {
  const AccountsView({super.key});

  @override
  State<AccountsView> createState() => _AccountsViewState();
}

class _AccountsViewState extends State<AccountsView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Accounts")),
      body: BlocConsumer<AccountsBloc, AccountsState>(
        listener: (context, state) {
          if (state is AccountOperationFailure) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          if (state is AccountsLoaded) {
            final accounts = state.accounts;
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
                                      (context) => AccountFormBloc(
                                        FinanceAccountService(),
                                      ),
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
          } else if (state is AccountOperationFailure) {
            return Text("error in fetching accounts");
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed:
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
                        child: CreateUpdateAccountView(isUpdate: false),
                      ),
                    ),
              ),
            ),
        child: Icon(Icons.add),
      ),
    );
  }
}
