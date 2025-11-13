// features/transactions/presentation/widgets/balance_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BalanceCard extends StatelessWidget {
  final String accountName;
  final String currentBalance; // Passed as a formatted string (or can be double/Decimal)
  final String currency;
  final bool isTotalBalance;

  const BalanceCard({
    required this.accountName,
    required this.currentBalance,
    required this.currency,
    this.isTotalBalance = false,
    super.key,
  });

  // Helper to format the currency
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
    
    // Choose the color based on whether it's the Total (primary) or an individual account (surface)
    // NOTE: We will use the primary color slightly subdued for the best visibility.
    final cardColor = isTotalBalance 
        ? theme.colorScheme.primary.withOpacity(0.9)
        : theme.colorScheme.surface;
    
    final textColor = isTotalBalance 
        ? theme.colorScheme.onPrimary // White/light text for the primary color background
        : theme.colorScheme.onSurface; // Dark text for the surface color background

    return Card(
      color: cardColor,
      elevation: 4, // Give it a nice lift
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 20.0), // Adds space before the transaction list
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Account Title/Label
            Text(
              isTotalBalance ? 'Total Net Balance' : '$accountName Balance',
              style: theme.textTheme.titleMedium?.copyWith(
                color: textColor.withOpacity(0.8),
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),

            // 2. The Main Balance Amount
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Display the formatted amount in a large, bold style
                Text(
                  _formatBalance(currentBalance, ''), // Format amount without the symbol here
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 36,
                    height: 1.1, // Adjust line height
                  ),
                ),
                const SizedBox(width: 8),

                // Display the Currency symbol/code slightly smaller
                Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Text(
                    currency,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: textColor.withOpacity(0.8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 3. Status/Metadata (Optional: Placeholder for quick insights)
            Row(
              children: [
                Icon(Icons.access_time_rounded, size: 16, color: textColor.withOpacity(0.6)),
                const SizedBox(width: 4),
                Text(
                  'Last updated: Today',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: textColor.withOpacity(0.6),
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