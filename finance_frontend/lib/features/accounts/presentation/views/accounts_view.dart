import 'package:finance_frontend/features/accounts/presentation/blocs/accounts/accounts_event.dart';
import 'package:finance_frontend/features/accounts/presentation/components/account_card.dart';
import 'package:finance_frontend/features/accounts/presentation/components/account_form_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:finance_frontend/features/accounts/domain/entities/account.dart'; 
import 'package:finance_frontend/features/accounts/data/services/finance_account_service.dart';
import 'package:finance_frontend/features/accounts/presentation/blocs/accounts/accounts_bloc.dart';
import 'package:finance_frontend/features/accounts/presentation/blocs/accounts/accounts_state.dart';
import 'package:finance_frontend/features/accounts/presentation/blocs/account_form/account_form_bloc.dart';


class AccountsView extends StatelessWidget {
  const AccountsView({super.key});

  void _showAccountFormModal(BuildContext context, {Account? account}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      builder: (BuildContext modalContext) {
        return MultiBlocProvider(
          providers: [
            BlocProvider.value(value: context.read<AccountsBloc>()),
            BlocProvider<AccountFormBloc>(
              create: (_) => AccountFormBloc(FinanceAccountService()),
            ),
          ],
          child: AccountFormModal(
            isUpdate: account != null,
            account: account,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Your Accounts",
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
      body: BlocConsumer<AccountsBloc, AccountsState>(
        listener: (context, state) {
          if (state is AccountOperationFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          List<Account> accounts = [];
          bool isThereError = false;
          bool isLoading = false;
          
          if (state is AccountsLoaded) {
            accounts = state.accounts;
          } else if (state is AccountOperationFailure) {
            isThereError = true;
            accounts = state.accounts;
          } else if (state is AccountsLoading || state is AccountsInitial) {
            isLoading = true;
          }

          if (isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (accounts.isEmpty && !isThereError) {
            return Center(
              child: Text(
                "No accounts found. Tap '+' to create one.",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                ),
              ),
            );
          }
          
          final activeAccounts = accounts.where((a) => a.active).toList();
          final inactiveAccounts = accounts.where((a) => !a.active).toList();
          
          return RefreshIndicator(
            onRefresh: () async {
              context.read<AccountsBloc>().add(RefreshAccounts());
            },
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                if (activeAccounts.isNotEmpty) ...[
                  Text(
                    'Active Accounts (${activeAccounts.length})',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12.0),
                  ...activeAccounts.map((account) => AccountCard(
                    account: account,
                    onTap: () => _showAccountFormModal(context, account: account),
                  )),
                  const SizedBox(height: 24.0),
                ],

                if (inactiveAccounts.isNotEmpty) ...[
                  Text(
                    'Inactive Accounts (${inactiveAccounts.length})',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withAlpha(178),
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  ...inactiveAccounts.map((account) => AccountCard(
                    account: account,
                    onTap: () => _showAccountFormModal(context, account: account),
                  )),
                ],
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAccountFormModal(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Account'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }
}