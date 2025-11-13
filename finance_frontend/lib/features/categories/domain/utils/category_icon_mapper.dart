// features/categories/domain/utils/category_icon_mapper.dart

import 'package:finance_frontend/features/categories/domain/entities/category.dart';
import 'package:finance_frontend/features/categories/domain/entities/category_type_enum.dart';
import 'package:flutter/material.dart';

extension CategoryIconMapper on FinanceCategory {
  /// Maps a category name to a specific Flutter IconData.
  IconData get displayIcon {
    // 1. Check Specific Category Names (Case-insensitive)
    switch (name.toLowerCase()) {
      case 'groceries':
      case 'food':
        return Icons.local_grocery_store_rounded;
      case 'salary':
      case 'wage':
        return Icons.work_outline_rounded;
      case 'rent':
      case 'housing':
        return Icons.home_work_outlined;
      case 'transport':
      case 'gas':
        return Icons.directions_car_filled_outlined;
      case 'subscriptions':
      case 'entertainment':
        return Icons.movie_filter_rounded;
      case 'health':
        return Icons.medical_services_outlined;
      case 'investments':
        return Icons.trending_up_rounded;
      case 'gifts':
        return Icons.card_giftcard_rounded;
      default:
        // 2. Fallback based on Category Type
        return type == CategoryType.INCOME
            ? Icons.attach_money_rounded
            : Icons.payments_rounded;
    }
  }
}