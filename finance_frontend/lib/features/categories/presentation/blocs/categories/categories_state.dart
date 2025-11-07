import 'package:equatable/equatable.dart';
import 'package:finance_frontend/features/categories/domain/entities/category.dart';
import 'package:flutter/foundation.dart';

@immutable
abstract class CategoriesState extends Equatable {
  const CategoriesState();
  @override
  List<Object?> get props => [];
}

class CategoriesInitial extends CategoriesState {
  const CategoriesInitial();
} // when the categories page is loading before any operation

class CategoriesLoading extends CategoriesState {
  const CategoriesLoading();
} // when the service is loading current user's categories (List<FinanceCategory>)

class CategoriesLoaded extends CategoriesState {
  final List<FinanceCategory> categories;
  const CategoriesLoaded(this.categories);

  @override
  List<Object?> get props => [categories];
} // when the service has finished loading the current user's categories (List<FinanceCategory>)

class CategoryOperationFailure extends CategoriesState {
  final List<FinanceCategory> categories;
  final String message;
  const CategoryOperationFailure(this.message, this.categories);

  @override
  List<Object?> get props => [message];
} // when any operation has failed
