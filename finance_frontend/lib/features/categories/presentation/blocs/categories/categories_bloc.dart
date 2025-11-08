import 'dart:developer' as developer;
import 'dart:io';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:finance_frontend/features/categories/domain/entities/category.dart';
import 'package:finance_frontend/features/categories/domain/exceptions/category_exceptions.dart';
import 'package:finance_frontend/features/categories/domain/service/category_service.dart';
import 'package:finance_frontend/features/categories/presentation/blocs/categories/categories_event.dart';
import 'package:finance_frontend/features/categories/presentation/blocs/categories/categories_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CategoriesBloc extends Bloc<CategoriesEvent, CategoriesState> {
  final CategoryService categoryService;

  List<FinanceCategory> _cachedcategories = [];

  CategoriesBloc(this.categoryService) : super(const CategoriesInitial()) {
    on<LoadCategories>(_onLoadCategories, transformer: droppable());
    on<RefreshCategories>(_onRefreshCategories, transformer: droppable());
    on<CategoryCreatedInForm>(_onCreatedCategory);
    on<CategoryUpdatedInForm>(_onUpdatedCategory);
    on<CategoryDeactivatedInForm>(_onDeactivatedCategory);
    on<CategoryRestoredInForm>(_onRestoredCategory);
    on<CategoryDeletedInForm>(_onDeletedCategory);

    add(LoadCategories());
  }

  Future<void> _onLoadCategories(
    LoadCategories event,
    Emitter<CategoriesState> emit,
  ) async {
    emit(const CategoriesLoading());
    try {
      final categories = await categoryService.getUserCategories();
      _cachedcategories = categories;
      emit(CategoriesLoaded(List.unmodifiable(_cachedcategories)));
    } catch (e) {
      emit(CategoriesOperationFailure(_mapErrorToMessage(e), _cachedcategories));
    }
  }

  Future<void> _onRefreshCategories(
    RefreshCategories event,
    Emitter<CategoriesState> emit,
  ) async {
    emit(CategoriesLoaded(List.unmodifiable(_cachedcategories)));
    try {
      final categories = await categoryService.getUserCategories();
      _cachedcategories = categories;
      emit(CategoriesLoaded(List.unmodifiable(_cachedcategories)));
    } catch (e, st) {
      developer.log('LoadCategories error', error: e, stackTrace: st);
      emit(CategoriesOperationFailure(_mapErrorToMessage(e), _cachedcategories));
    }
  }

  Future<void> _onCreatedCategory(
    CategoryCreatedInForm event,
    Emitter<CategoriesState> emit,
  ) async {
    final updated = List<FinanceCategory>.from(_cachedcategories);
    updated.insert(0, event.category);
    _cachedcategories = updated;
    emit(CategoriesLoaded(List.unmodifiable(_cachedcategories)));
  }

  Future<void> _onUpdatedCategory(
    CategoryUpdatedInForm event,
    Emitter<CategoriesState> emit,
  ) async {
    final index = _cachedcategories.indexWhere((a) => a.id == event.category.id);
    if (index != -1) {
      final updated = List<FinanceCategory>.from(_cachedcategories);
      updated[index] = event.category;
      _cachedcategories = updated;
      emit(CategoriesLoaded(List.unmodifiable(_cachedcategories)));
    }
  }

  Future<void> _onDeactivatedCategory(
    CategoryDeactivatedInForm event,
    Emitter<CategoriesState> emit,
  ) async {
    final index = _cachedcategories.indexWhere((a) => a.id == event.category.id);
    if (index != -1) {
      final updated = List<FinanceCategory>.from(_cachedcategories);
      updated[index] = event.category;
      _cachedcategories = updated;
      emit(CategoriesLoaded(List.unmodifiable(_cachedcategories)));
    }
  }

  Future<void> _onRestoredCategory(
    CategoryRestoredInForm event,
    Emitter<CategoriesState> emit,
  ) async {
    final index = _cachedcategories.indexWhere((a) => a.id == event.category.id);
    if (index != -1) {
      final updated = List<FinanceCategory>.from(_cachedcategories);
      updated[index] = event.category;
      _cachedcategories = updated;
      emit(CategoriesLoaded(List.unmodifiable(_cachedcategories)));
    }
  }

  Future<void> _onDeletedCategory(
    CategoryDeletedInForm event,
    Emitter<CategoriesState> emit,
  ) async {
    final updated = List<FinanceCategory>.from(_cachedcategories);
    updated.removeWhere((a) => a.id == event.id);
    _cachedcategories = updated;
    emit(CategoriesLoaded(List.unmodifiable(_cachedcategories)));
  }

  String _mapErrorToMessage(Object e) {
    if (e is CouldnotFetchCategories) return 'Couldnot fetch categories, please try reloading the page';
    if(e is SocketException) return 'No Internet connection!, please try connecting to the internet';
    return e.toString();
    
  }
}
