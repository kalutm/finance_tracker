import 'package:finance_frontend/features/categories/domain/exceptions/category_exceptions.dart';
import 'package:finance_frontend/features/categories/domain/service/category_service.dart';
import 'package:finance_frontend/features/categories/presentation/blocs/category_form/category_form_event.dart';
import 'package:finance_frontend/features/categories/presentation/blocs/category_form/category_form_state.dart';
import 'package:finance_frontend/features/categories/presentation/blocs/entities/operation_type_enum.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CategoryFormBloc extends Bloc<CategoryFormEvent, CategoryFormState> {
  final CategoryService service;

  CategoryFormBloc(this.service) : super(CategoryFormInitial()) {
    on<CreateCategory>(_onCreate);
    on<GetCategory>(_onGet);
    on<UpdateCategory>(_onUpdate);
    on<DeactivateCategory>(_onDeactivate);
    on<RestoreCategory>(_onRestore);
    on<DeleteCategory>(_onDelete);

  }

  Future<void> _onCreate(
    CreateCategory event,
    Emitter<CategoryFormState> emit,
  ) async {
    try {
      emit(CategoryOperationInProgress());
      final category = await service.createCategory(event.create);
      emit(CategoryOperationSuccess(category, CategoryOperationType.create));
    } catch (e) {
      emit(CategoryOperationFailure(_mapErrorToMessage(e)));
    }
  }

  Future<void> _onGet(
    GetCategory event,
    Emitter<CategoryFormState> emit,
  ) async {
    try {
      emit(CategoryOperationInProgress());
      final category = await service.getCategory(event.id);
      emit(CategoryOperationSuccess(category, CategoryOperationType.read));
    } catch (e) {
      emit(CategoryOperationFailure(_mapErrorToMessage(e)));
    }
  }

  Future<void> _onUpdate(
    UpdateCategory event,
    Emitter<CategoryFormState> emit,
  ) async {
    try {
      emit(CategoryOperationInProgress());
      final category = await service.updateCategory(event.id, event.patch);
      emit(CategoryOperationSuccess(category, CategoryOperationType.update));
    } catch (e) {
      emit(CategoryOperationFailure(_mapErrorToMessage(e)));
    }
  }

  Future<void> _onDeactivate(
    DeactivateCategory event,
    Emitter<CategoryFormState> emit,
  ) async {
    try {
      emit(CategoryOperationInProgress());
      final category = await service.deactivateCategory(event.id);
      emit(CategoryOperationSuccess(category, CategoryOperationType.deactivate));
    } catch (e) {
      emit(CategoryOperationFailure(_mapErrorToMessage(e)));
    }
  }

  Future<void> _onRestore(
    RestoreCategory event,
    Emitter<CategoryFormState> emit,
  ) async {
    try {
      emit(CategoryOperationInProgress());
      final category = await service.restoreCategory(event.id);
      emit(CategoryOperationSuccess(category, CategoryOperationType.restore));
    } catch (e) {
      emit(CategoryOperationFailure(_mapErrorToMessage(e)));
    }
  }

  Future<void> _onDelete(
    DeleteCategory event,
    Emitter<CategoryFormState> emit,
  ) async {
    try {
      emit(CategoryOperationInProgress());
      await service.deleteCategory(event.id);
      emit(CategoryDeleteOperationSuccess(event.id));
    } catch (e) {
      emit(CategoryOperationFailure(_mapErrorToMessage(e)));
    }
  }

  String _mapErrorToMessage(Object e) {
    if (e is CouldnotCreateCategory) return 'Couldnot create category, please try using another category name';
    if (e is CouldnotGetCategory) return 'Couldnot get category or Account not found';
    if (e is CouldnotUpdateCategory) return 'Couldnot Update category, please try using another category name';
    if (e is CouldnotDeactivateCategory) return 'Couldnot Deactivate category, please try again';
    if (e is CouldnotRestoreCategory) return 'Couldnot Restore category, please try again';
    if (e is CouldnotDeleteCategory) return 'Couldnot Delete category, please try again';
    return e.toString();
  }
}