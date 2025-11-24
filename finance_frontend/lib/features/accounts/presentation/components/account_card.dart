import 'package:flutter/material.dart';
import 'package:finance_frontend/features/accounts/domain/entities/account.dart'; 
import 'package:finance_frontend/features/accounts/domain/entities/account_type_enum.dart'; 

class AccountCard extends StatelessWidget {
  final Account account;
  final VoidCallback onTap;

  const AccountCard({
    required this.account,
    required this.onTap,
    super.key,
  });

  IconData _getIconForType(AccountType type) {
    switch (type) {
      case AccountType.CASH: return Icons.money_outlined;
      case AccountType.BANK: return Icons.account_balance_rounded;
      case AccountType.CREDIT_CARD: return Icons.credit_card_rounded;
      case AccountType.CRYPTO: return Icons.currency_bitcoin_outlined;
      default: return Icons.wallet_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
  
    final isActive = account.active;
    final cardOpacity = isActive ? 1.0 : 0.4;
    final cardColor = isActive 
        ? theme.colorScheme.surface 
        : theme.colorScheme.surface.withAlpha(127);

    return Opacity(
      opacity: cardOpacity,
      child: Card(
        color: cardColor,
        elevation: isActive ? 2 : 0,
        margin: const EdgeInsets.only(bottom: 12.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
          side: !isActive 
              ? BorderSide(color: theme.colorScheme.onSurface.withAlpha(26), width: 1.0)
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.0),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _getIconForType(account.type),
                      color: theme.colorScheme.primary,
                      size: 30,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        account.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!isActive)
                      Chip(
                        label: Text('INACTIVE'),
                        backgroundColor: theme.colorScheme.error.withAlpha(26),
                        labelStyle: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '${account.currency} ${account.balance}', 
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Type: ${account.type.name.replaceAll('_', ' ')}',
                  style: theme.textTheme.labelMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}