import 'package:finance_frontend/core/provider/providers.dart';
import 'package:finance_frontend/features/accounts/presentation/blocs/account_form/account_form_bloc.dart';
import 'package:finance_frontend/features/accounts/presentation/blocs/accounts/accounts_bloc.dart';
import 'package:finance_frontend/features/accounts/presentation/views/accounts_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AccountsWrapper extends ConsumerWidget {
  const AccountsWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: context.read<AccountsBloc>()),
        BlocProvider<AccountFormBloc>(
          create: (_) => AccountFormBloc(ref.read(accountServiceProvider)),
        ),
      ],
      child: const AccountsView(),
    );
  }
}
