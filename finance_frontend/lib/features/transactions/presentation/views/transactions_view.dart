import 'package:finance_frontend/features/accounts/domain/entities/account.dart';
import 'package:finance_frontend/features/accounts/domain/utils/account_icom_map.dart';
import 'package:finance_frontend/features/accounts/presentation/blocs/accounts/accounts_bloc.dart';
import 'package:finance_frontend/features/accounts/presentation/blocs/accounts/accounts_state.dart';
import 'package:finance_frontend/features/categories/presentation/blocs/categories/categories_bloc.dart';
import 'package:finance_frontend/features/transactions/domain/entities/transaction.dart';
import 'package:finance_frontend/features/transactions/presentation/bloc/transaction_form/transaction_form_bloc.dart';
import 'package:finance_frontend/features/transactions/presentation/bloc/transactions/transactions_bloc.dart';
import 'package:finance_frontend/features/transactions/presentation/bloc/transactions/transactions_event.dart';
import 'package:finance_frontend/features/transactions/presentation/bloc/transactions/transactions_state.dart';
import 'package:finance_frontend/features/transactions/presentation/components/balance_card.dart';
import 'package:finance_frontend/features/transactions/presentation/components/transaction_list_item.dart';
import 'package:finance_frontend/features/transactions/presentation/views/transaction_form_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:decimal/decimal.dart';

class TransactionsView extends StatelessWidget {
  const TransactionsView({super.key});

  void _showTransactionForm(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder:
            (modalContext) => MultiBlocProvider(
              providers: [
                BlocProvider.value(value: context.read<TransactionFormBloc>()),
                BlocProvider.value(value: context.read<AccountsBloc>()),
                BlocProvider.value(value: context.read<CategoriesBloc>()),
              ],
              child: const TransactionFormModal(),
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: _buildAccountSelector(context, theme),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Transactions',
            onPressed: () {
              context.read<TransactionsBloc>().add(const RefreshTransactions());
            },
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: BlocConsumer<TransactionsBloc, TransactionsState>(
        listener: (context, state) {
          if (state is TransactionOperationFailure) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          if (state is TransactionsInitial || state is TransactionsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          List<Transaction> transactions = [];
          Account? selectedAccount;

          if (state is TransactionsLoaded) {
            transactions = state.transactions;
            selectedAccount = state.account;
          } else if (state is TransactionOperationFailure) {
            transactions = state.transactions;
            selectedAccount = state.account;
          }

          if (transactions.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long_rounded,
                      size: 64,
                      color: theme.colorScheme.primary.withAlpha(153),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      selectedAccount == null
                          ? 'No transactions found across all accounts.'
                          : 'No transactions found for ${selectedAccount.name}.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap the "+" button to record your first transaction!',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(178),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<TransactionsBloc>().add(const RefreshTransactions());
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 20.0,
              ),
              itemCount: transactions.length + 1,
              itemBuilder: (context, index) {
                // First item is the Balance Card
                if (index == 0) {
                  // Wrap the balance area with AccountsBloc builder so it rebuilds when accounts change
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BlocBuilder<AccountsBloc, AccountsState>(
                        builder: (accountsContext, accountsState) {
                          final balanceData = _calculateTotalBalanceFromState(
                            accountsState,
                            selectedAccount,
                          );
                          return BalanceCard(
                            accountName:
                                selectedAccount?.name ?? 'All Accounts',
                            currentBalance: balanceData['balance'] as String,
                            currency: balanceData['currency'] as String,
                            isTotalBalance: selectedAccount == null,
                          );
                        },
                      ),
                    ],
                  );
                }

                // Transaction List Items
                final transaction = transactions[index - 1];
                return TransactionListItem(transaction: transaction);
              },
            ),
          );
        },
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTransactionForm(context),
        label: const Text('New Transaction'),
        icon: const Icon(Icons.add),
        backgroundColor: theme.colorScheme.secondary,
        foregroundColor: theme.colorScheme.onSecondary,
      ),
    );
  }

  Widget _buildAccountSelector(BuildContext context, ThemeData theme) {
    return BlocBuilder<AccountsBloc, AccountsState>(
      builder: (accountsContext, accountsState) {
        if (accountsState is AccountsLoaded) {
          final allAccounts = accountsState.accounts;
          final List<Account?> displayAccounts = [null, ...allAccounts];

          return BlocBuilder<TransactionsBloc, TransactionsState>(
            buildWhen: (p, c) {
              final pId = (p is TransactionsLoaded ? p.account?.id : null);
              final cId = (c is TransactionsLoaded ? c.account?.id : null);
              if (p.runtimeType != c.runtimeType) return true;
              return pId != cId;
            },
            builder: (txContext, txState) {
              Account? selectedAccountFromTx;
              if (txState is TransactionsLoaded) {
                selectedAccountFromTx = txState.account;
              } else if (txState is TransactionOperationFailure) {
                selectedAccountFromTx = txState.account;
              }

              Account? dropdownValue = displayAccounts.firstWhere(
                (a) => a?.id == selectedAccountFromTx?.id,
                orElse: () => selectedAccountFromTx,
              );

              if (!displayAccounts.contains(dropdownValue)) {
                dropdownValue = null;
              }

              return DropdownButtonHideUnderline(
                child: DropdownButton<Account?>(
                  value: dropdownValue,
                  icon: Icon(
                    Icons.arrow_drop_down,
                    color: theme.colorScheme.onPrimary,
                  ),
                  dropdownColor: theme.colorScheme.surface,
                  hint: Text(
                    selectedAccountFromTx?.name ?? 'All Accounts',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  onChanged: (Account? newAccount) {
                    txContext.read<TransactionsBloc>().add(
                      TransactionFilterChanged(newAccount),
                    );
                  },

                  items:
                      displayAccounts.map((account) {
                        final name = account?.name ?? 'All Accounts';
                        final bool isSelected =
                            account?.id == selectedAccountFromTx?.id;

                        return DropdownMenuItem<Account?>(
                          value: account,
                          child: Row(
                            children: [
                              Icon(
                                account?.displayIcon ??
                                    Icons.account_balance_wallet_rounded,
                                color:
                                    isSelected
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurface.withAlpha(
                                          178,
                                        ),
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color:
                                      isSelected
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                ),
              );
            },
          );
        }
        return const Text('Transactions');
      },
    );
  }

  // balance calculation from account's state to update whenever a transaction crud
  Map<String, String> _calculateTotalBalanceFromState(
    AccountsState accountsState,
    Account? selectedAccount,
  ) {
    Decimal totalBalance = Decimal.zero;
    String currency = 'MIX'; // Default for mixed/total balance

    List<Account> accountsList = [];
    if (accountsState is AccountsLoaded) {
      accountsList = accountsState.accounts;
    } else if (accountsState is AccountOperationFailure) {
      accountsList = accountsState.accounts;
    }

    if (selectedAccount != null) {
      // If a specific account is selected, try to find the authoritative account instance by id
      try {
        final currAccount = accountsList.firstWhere(
          (a) => a.id == selectedAccount.id,
        );
        totalBalance = currAccount.balanceValue;
        currency = currAccount.currency;
      } catch (_) {
        // if not found first where -> state error, we try to use the passed selectedAccount's balance
        try {
          totalBalance = selectedAccount.balanceValue;
          currency = selectedAccount.currency;
        } catch (_) {
          return {'balance': 'Error', 'currency': selectedAccount.currency};
        }
      }
    } else {
      // Sum all accounts (if any)
      if (accountsList.isNotEmpty) {
        currency = accountsList.first.currency;
      }
      for (var account in accountsList) {
        totalBalance += account.balanceValue;
      }
    }

    return {'balance': totalBalance.toStringAsFixed(2), 'currency': currency};
  }
}
