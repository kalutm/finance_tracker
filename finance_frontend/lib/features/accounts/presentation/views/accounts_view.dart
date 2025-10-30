import 'package:finance_frontend/features/accounts/data/services/finance_account_service.dart';
import 'package:finance_frontend/features/accounts/presentation/blocs/account_form/account_form_bloc.dart';
import 'package:finance_frontend/features/accounts/presentation/blocs/accounts/accounts_bloc.dart';
import 'package:finance_frontend/features/accounts/presentation/blocs/accounts/accounts_state.dart';
import 'package:finance_frontend/features/auth/data/services/finance_secure_storage_service.dart';
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
    return MultiBlocProvider(
      providers: [
        BlocProvider<AccountsBloc>(
          create:
              (context) => AccountsBloc(
                FinanceAccountService(FinanceSecureStorageService()),
              ),
        ),
        BlocProvider<AccountFormBloc>(
          create:
              (context) => AccountFormBloc(
                FinanceAccountService(FinanceSecureStorageService()),
              ),
        ),
      ],
      child: Scaffold(
        appBar: AppBar(title: Text("Accounts")),
        body: BlocConsumer<AccountsBloc, AccountsState>(
          listener: (context, state) {
            if(state is AccountOperationFailure){
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          builder: (context, state) {
            if(state is AccountsLoaded){
              final accounts = state.accounts;
              return ListView.builder(itemCount: accounts.length, itemBuilder: (context, index) {
                final account = accounts[index];
                return ListTile(
                  leading: Text(account.currency),
                  title: Text(account.name),
                  subtitle: Text(account.balance),
                  trailing: Text(account.type.name),
                );
              });
            } else if (state is AccountOperationFailure){
              return Text("error in fetching accounts");
            } else{
              return Center(
                child: CircularProgressIndicator(),
              );
            }
          },
        ),
      ),
    );
  }
}
