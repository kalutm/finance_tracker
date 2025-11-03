import 'package:finance_frontend/features/accounts/data/services/finance_account_service.dart';
import 'package:finance_frontend/features/accounts/presentation/blocs/accounts/accounts_bloc.dart';
import 'package:finance_frontend/features/accounts/presentation/views/accounts_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AccountsWrapper extends StatelessWidget {
  const AccountsWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AccountsBloc>(
      create: (_) => AccountsBloc(FinanceAccountService()),
      child: const AccountsView(),
    );
  }
}