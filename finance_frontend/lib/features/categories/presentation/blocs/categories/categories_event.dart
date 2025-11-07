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
} // when ever the ui needs to load the current user's categories (List<FinanceCategory>)

class RefreshCategories extends CategoriesEvent {
  const RefreshCategories();
} // when ever the ui needs to refresh the current user's accounts (List<FinanceCAtegory>)

class CategoryCreatedInForm extends CategoriesEvent {
  final FinanceCategory category;
  const CategoryCreatedInForm(this.category);

  @override
  List<Object?> get props => [category];
} // when a user has created a new category in form

class CategoryUpdatedInForm extends CategoriesEvent {
  final FinanceCategory category;
  const CategoryUpdatedInForm(this.category);

  @override
  List<Object?> get props => [category];
} // when the has updated an category in form

class CategoryDeactivatedInForm extends CategoriesEvent {
  final FinanceCategory category;
  const CategoryDeactivatedInForm(this.category);

  @override
  List<Object?> get props => [category];
} // when the user has soft deleted an category in form

class CategoryRestoredInForm extends CategoriesEvent {
  final FinanceCategory category;
  const CategoryRestoredInForm(this.category);

  @override
  List<Object?> get props => [category];
} // when the user has restored an category in form

class CategoryDeletedInForm extends CategoriesEvent {
  final String id;
  const CategoryDeletedInForm(this.id);

  @override
  List<Object?> get props => [id];
} // when the user wants to hard delete an category 
