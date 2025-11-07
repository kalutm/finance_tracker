import 'package:equatable/equatable.dart';
import 'package:finance_frontend/features/categories/domain/entities/category.dart';
import 'package:finance_frontend/features/categories/presentation/blocs/entities/operation_type_enum.dart';
import 'package:flutter/foundation.dart';

@immutable
abstract class CategoryFormState extends Equatable {
  const CategoryFormState();
  @override
  List<Object?> get props => [];
}


class CategoryFormInitial extends CategoryFormState {
  const CategoryFormInitial();
} // when the category form page is loading before any operation

class CategoryOperationInProgress extends CategoryFormState {
  const CategoryOperationInProgress();
} // when the service is doing any crud operation

class CategoryOperationSuccess extends CategoryFormState{
  final FinanceCategory category;
  final CategoryOperationType operationType;
  const CategoryOperationSuccess(this.category, this.operationType);

  @override
  List<Object?> get props => [category, operationType];
} // when any Create, Read and Update operation on an category has successfully completed

class CategoryDeleteOperationSuccess extends CategoryFormState{
  final String id;
  const CategoryDeleteOperationSuccess(this.id);

  @override
  List<Object?> get props => [id];
} // when a delete Operation on an category has successfully completed

class CategoryOperationFailure extends CategoryFormState {
  final String message;
  const CategoryOperationFailure(this.message);

  @override
  List<Object?> get props => [message];
} // when any operation has failed
