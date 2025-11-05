import 'package:finance_frontend/features/accounts/data/services/finance_account_service.dart';
import 'package:finance_frontend/features/accounts/presentation/blocs/account_form/account_form_bloc.dart';
import 'package:finance_frontend/features/accounts/presentation/blocs/accounts/accounts_bloc.dart';
import 'package:finance_frontend/features/accounts/presentation/blocs/accounts/accounts_state.dart';
import 'package:finance_frontend/features/accounts/presentation/components/accounts_list.dart';
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
            return AccountsList(accounts: accounts);
          } else if (state is AccountOperationFailure) {
            return AccountsList(accounts: state.accounts);
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
