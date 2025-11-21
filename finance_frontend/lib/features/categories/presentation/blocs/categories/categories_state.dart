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
}

class CategoriesLoading extends CategoriesState {
  const CategoriesLoading();
}

class CategoriesLoaded extends CategoriesState {
  final List<FinanceCategory> categories;
  final String _fingerprint;

  CategoriesLoaded(this.categories) : _fingerprint = _computeFingerprint(categories);

  static String _computeFingerprint(List<FinanceCategory> categories) {
    return categories.map((c) => '${c.id}:${c.name}:${c.active}').join('|');
  }

  @override
  List<Object?> get props => [categories, _fingerprint];
}

class CategoriesOperationFailure extends CategoriesState {
  final List<FinanceCategory> categories;
  final String message;
  final String _fingerprint;

  CategoriesOperationFailure(this.message, this.categories)
      : _fingerprint = CategoriesLoaded._computeFingerprint(categories);

  @override
  List<Object?> get props => [message, categories, _fingerprint];
}
