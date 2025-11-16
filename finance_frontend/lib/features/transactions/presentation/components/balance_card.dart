import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BalanceCard extends StatelessWidget {
  final String accountName;
  final String currentBalance;
  final String currency;
  final bool isTotalBalance;

  const BalanceCard({
    required this.accountName,
    required this.currentBalance,
    required this.currency,
    this.isTotalBalance = false,
    super.key,
  });

  String _formatBalance(String balance, String currency) {
    try {
      final balanceDouble = double.tryParse(balance) ?? 0.0;
      final formatter = NumberFormat.currency(
        locale: 'en_US',
        symbol: currency,
        decimalDigits: 2,
      );
      return formatter.format(balanceDouble);
    } catch (_) {
      return '$currency ${balance}'; // Fallback
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final cardColor =
        isTotalBalance
            ? theme.colorScheme.primary.withAlpha(230)
            : theme.colorScheme.surface;

    final textColor =
        isTotalBalance
            ? theme
                .colorScheme
                .onPrimary
            : theme
                .colorScheme
                .onSurface; 

    return Card(
      color: cardColor,
      elevation: 4, 
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(
        bottom: 20.0,
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isTotalBalance ? 'Total Net Balance' : '$accountName Balance',
              style: theme.textTheme.titleMedium?.copyWith(
                color: textColor.withAlpha(204),
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),

            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatBalance(
                    currentBalance,
                    '',
                  ),
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 36,
                    height: 1.1,
                  ),
                ),
                const SizedBox(width: 8),

                Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Text(
                    currency,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: textColor.withAlpha(204),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 3. Status/Metadata Placeholder for quick insights : i will implement it in the future
            Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 16,
                  color: textColor.withAlpha(153),
                ),
                const SizedBox(width: 4),
                Text(
                  'Last updated: Today',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: textColor.withAlpha(153),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
