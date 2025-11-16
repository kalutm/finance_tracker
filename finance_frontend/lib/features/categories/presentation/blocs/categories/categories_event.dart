import 'package:equatable/equatable.dart';
import 'package:finance_frontend/features/categories/domain/entities/category.dart';
import 'package:flutter/foundation.dart';

@immutable
abstract class CategoriesEvent extends Equatable {
  const CategoriesEvent();
  @override
  List<Object?> get props => [];
}

class LoadCategories extends CategoriesEvent {
  const LoadCategories();
}

class RefreshCategories extends CategoriesEvent {
  const RefreshCategories();
}

/// Internal event triggered when the category service stream emits a new list.
class CategoriesUpdated extends CategoriesEvent {
  final List<FinanceCategory> categories;
  const CategoriesUpdated(this.categories);

  @override
  List<Object?> get props => [categories];
}
