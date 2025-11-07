import 'package:equatable/equatable.dart';
import 'package:finance_frontend/features/categories/domain/entities/dtos/category_create.dart';
import 'package:finance_frontend/features/categories/domain/entities/dtos/category_patch.dart';
import 'package:flutter/foundation.dart';

@immutable
abstract class CategoryFormEvent extends Equatable {
  const CategoryFormEvent();
  @override
  List<Object?> get props => [];
} 

class CreateCategory extends CategoryFormEvent {
  final CategoryCreate create;
  const CreateCategory(this.create);

  @override
  List<Object?> get props => [create];
} // when a user wants to create a new category

class GetCategory extends CategoryFormEvent {
  final String id;
  const GetCategory(this.id);

  @override
  List<Object?> get props => [id];
} // when the user wants to fetch a single category

class UpdateCategory extends CategoryFormEvent {
  final String id;
  final CategoryPatch patch;
  const UpdateCategory(this.id, this.patch);

  @override
  List<Object?> get props => [id, patch];
} // when the user wants to modify an category

class DeactivateCategory extends CategoryFormEvent {
  final String id;
  const DeactivateCategory(this.id);

  @override
  List<Object?> get props => [id];
} // when the user wants to soft delete an category 

class RestoreCategory extends CategoryFormEvent {
  final String id;
  const RestoreCategory(this.id);

  @override
  List<Object?> get props => [id];
} // when the user wants to restore the soft deleted accoutn

class DeleteCategory extends CategoryFormEvent {
  final String id;
  const DeleteCategory(this.id);

  @override
  List<Object?> get props => [id];
} // when the user wants to hard delete an category 
