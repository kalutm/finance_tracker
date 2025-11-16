import 'package:finance_frontend/features/accounts/presentation/blocs/accounts/accounts_bloc.dart';
import 'package:finance_frontend/features/categories/presentation/blocs/categories/categories_bloc.dart';
import 'package:finance_frontend/features/transactions/domain/entities/transaction.dart';
import 'package:finance_frontend/features/transactions/domain/entities/transaction_type.dart';
import 'package:finance_frontend/features/transactions/presentation/bloc/transaction_form/transaction_form_bloc.dart';
import 'package:finance_frontend/features/transactions/presentation/views/transaction_form_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class TransactionListItem extends StatelessWidget {
  final Transaction transaction;

  const TransactionListItem({required this.transaction, super.key});

  Color _getAmountColor(BuildContext context, ThemeData theme) {
    final isExpense = transaction.type == TransactionType.EXPENSE;
    final isIncome = transaction.type == TransactionType.INCOME;

    if (isExpense) {
      return theme.colorScheme.error;
    } else if (isIncome) {
      return const Color(0xFF4CAF50);
    } else {
      return theme.colorScheme.primary;
    }
  }

  String _getAmountPrefix() {
    if (transaction.type == TransactionType.EXPENSE) return '-';
    if (transaction.type == TransactionType.INCOME) return '+';
    return '';
  }

  IconData _getIconData() {
    if (transaction.type == TransactionType.TRANSFER) {
      return Icons.swap_horiz_rounded;
    }
    if (transaction.type == TransactionType.INCOME) {
      return Icons.trending_up_rounded;
    }
    return Icons.shopping_bag_rounded;
  }

  void _openEditModal(BuildContext context) {
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
              child: TransactionFormModal(initialTransaction: transaction),
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amountColor = _getAmountColor(context, theme);

    final formattedAmount = NumberFormat.currency(
      locale: 'en_US',
      symbol: transaction.currency,
      decimalDigits: 2,
    ).format(double.tryParse(transaction.amount) ?? 0.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () => _openEditModal(context),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.onSurface.withAlpha(13),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: amountColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_getIconData(), color: amountColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.description ?? transaction.type.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${transaction.merchant ?? transaction.type} • ${DateFormat.yMd().format(transaction.occuredAt)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(178),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${_getAmountPrefix()}${formattedAmount}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: amountColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Acc. ID: ${transaction.accountId}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
