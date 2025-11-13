// features/transactions/presentation/views/transactions_page.dart

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
import 'package:decimal/decimal.dart'; // Required for accurate math

class TransactionsView extends StatelessWidget {
  const TransactionsView({super.key});

  void _showTransactionForm(BuildContext context) {
    // Open the full-screen transaction form
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
        automaticallyImplyLeading: true, // Show the drawer icon
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
          // --- LOADING & ERROR STATES ---
          if (state is TransactionsInitial || state is TransactionsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          List<Transaction> transactions = [];
          Account? selectedAccount;
          String?
          errorMessage; // To display error messages if a failure occurred

          if (state is TransactionsLoaded) {
            transactions = state.transactions;
            selectedAccount = state.account;
          } else if (state is TransactionOperationFailure) {
            transactions = state.transactions;
            selectedAccount = state.account;
            errorMessage = state.message;
          }

          // --- Empty State Check ---
          if (transactions.isEmpty && errorMessage == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long_rounded,
                      size: 64,
                      color: theme.colorScheme.primary.withOpacity(0.6),
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
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // --- UI STRUCTURE ---
          return RefreshIndicator(
            onRefresh: () async {
              context.read<TransactionsBloc>().add(const RefreshTransactions());
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 20.0,
              ),
              itemCount: transactions.length + 1, // +1 for the BalanceCard
              itemBuilder: (context, index) {
                // First item is the Balance Card
                if (index == 0) {
                  // --- Balance Calculation (Accurate) ---
                  final balanceData = _calculateTotalBalance(
                    context,
                    selectedAccount,
                  );

                  // --- Error Message Banner (if applicable) ---
                  final errorWidget =
                      errorMessage != null
                          ? Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    color: theme.colorScheme.error,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Error: $errorMessage',
                                      style: TextStyle(
                                        color: theme.colorScheme.error,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          : const SizedBox.shrink();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      errorWidget,
                      BalanceCard(
                        accountName: selectedAccount?.name ?? 'All Accounts',
                        currentBalance: balanceData['balance'] as String,
                        currency: balanceData['currency'] as String,
                        isTotalBalance: selectedAccount == null,
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

  // --- Account Selector Widget (Refined) ---
  Widget _buildAccountSelector(BuildContext context, ThemeData theme) {
    return BlocBuilder<AccountsBloc, AccountsState>(
      builder: (accountsContext, accountsState) {
        if (accountsState is AccountsLoaded) {
          final allAccounts = accountsState.accounts;
          final List<Account?> displayAccounts = [null, ...allAccounts];

          return BlocBuilder<TransactionsBloc, TransactionsState>(
            buildWhen:
                (p, c) =>
                    (p is TransactionsLoaded &&
                        c is TransactionsLoaded &&
                        p.account != c.account) ||
                    p.runtimeType != c.runtimeType,
            builder: (txContext, txState) {
              Account? selectedAccount;
              if (txState is TransactionsLoaded) {
                selectedAccount = txState.account;
              } else if (txState is TransactionOperationFailure) {
                selectedAccount = txState.account;
              }

              return DropdownButtonHideUnderline(
                child: DropdownButton<Account?>(
                  value: selectedAccount,
                  icon: Icon(
                    Icons.arrow_drop_down,
                    color: theme.colorScheme.onPrimary,
                  ),
                  dropdownColor: theme.colorScheme.surface,

                  // Use a Custom Title Widget to ensure the color is correct when the item is selected
                  hint: Text(
                    selectedAccount?.name ?? 'All Accounts',
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

                        return DropdownMenuItem<Account?>(
                          value: account,
                          child: Row(
                            children: [
                              // *** INTEGRATE ACCOUNT ICON MAPPER ***
                              Icon(
                                account?.displayIcon ??
                                    Icons.account_balance_wallet_rounded,
                                color:
                                    account == selectedAccount
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurface
                                            .withOpacity(0.7),
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color:
                                      account == selectedAccount
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

  // --- ACCURATE BALANCE CALCULATION ---
  Map<String, String> _calculateTotalBalance(
    BuildContext context,
    Account? selectedAccount,
  ) {
    final accountsState = context.read<AccountsBloc>().state;
    Decimal totalBalance = Decimal.zero;
    String currency = 'MIX'; // Default for mixed/total balance

    if (selectedAccount != null) {
      // 1. Single Account: Use its balance and currency directly
      try {
        totalBalance = selectedAccount.balanceValue;
        currency = selectedAccount.currency;
      } catch (e) {
        // Handle parsing error if the balance string is invalid
        return {'balance': 'Error', 'currency': selectedAccount.currency};
      }
    } else if (accountsState is AccountsLoaded) {
      // 2. All Accounts: Sum balances. NOTE: This is only accurate if all accounts use the same currency.
      // For simplicity, we assume a single base currency or display the sum regardless.

      // Determine the primary currency (e.g., the first account's currency)
      if (accountsState.accounts.isNotEmpty) {
        currency = accountsState.accounts.first.currency;
      }

      // Sum the balances
      for (var account in accountsState.accounts) {
        try {
          totalBalance += account.balanceValue;
        } catch (e) {
          // Log the error but continue summing others
          print('Error parsing balance for account ${account.name}: $e');
        }
      }
    }

    return {
      // Use toDecimal to format the Decimal to a standard string
      'balance': totalBalance.toStringAsFixed(2),
      'currency': currency,
    };
  }
}
