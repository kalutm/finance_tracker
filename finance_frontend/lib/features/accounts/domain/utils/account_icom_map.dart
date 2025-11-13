// features/accounts/domain/utils/account_icon_mapper.dart

import 'package:finance_frontend/features/accounts/domain/entities/account.dart';
import 'package:finance_frontend/features/accounts/domain/entities/account_type_enum.dart';
import 'package:flutter/material.dart';

extension AccountIconMapper on Account {
  /// Maps the account type to a specific Flutter IconData.
  IconData get displayIcon {
    switch (type) {
      case AccountType.CASH:
        return Icons.money_rounded;
      case AccountType.BANK:
        return Icons.account_balance_rounded;
      case AccountType.CREDIT_CARD:
        return Icons.credit_card_rounded;
      case AccountType.CRYPTO:
        return Icons.currency_bitcoin;
      default:
        return Icons.wallet_rounded;
    }
  }
}