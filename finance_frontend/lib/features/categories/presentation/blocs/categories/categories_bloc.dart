import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:finance_frontend/features/categories/domain/entities/category.dart';
import 'package:finance_frontend/features/categories/domain/exceptions/category_exceptions.dart';
import 'package:finance_frontend/features/categories/domain/service/category_service.dart';
import 'categories_event.dart';
import 'categories_state.dart';

class CategoriesBloc extends Bloc<CategoriesEvent, CategoriesState> {
  final CategoryService categoryService;
  StreamSubscription<List<FinanceCategory>>? _sub;

  CategoriesBloc(this.categoryService) : super(const CategoriesInitial()) {
    on<LoadCategories>(_onLoadCategories, transformer: droppable());
    on<RefreshCategories>(_onRefreshCategories, transformer: droppable());
    on<CategoriesUpdated>(_onCategoriesUpdated);


    _sub = categoryService.categoriesStream.listen(
      (categories) => add(CategoriesUpdated(categories)),
      onError: (err, st) {
        developer.log('CategoryService stream error', error: err, stackTrace: st);
      },
    );

    add(const LoadCategories());
  }

  Future<void> _onLoadCategories(LoadCategories event, Emitter<CategoriesState> emit) async {
    emit(const CategoriesLoading());
    try {
      final categories = await categoryService.getUserCategories();
      emit(CategoriesLoaded(List.unmodifiable(categories)));
    } catch (e) {
      emit(CategoriesOperationFailure(_mapErrorToMessage(e), const []));
    }
  }

  Future<void> _onRefreshCategories(RefreshCategories event, Emitter<CategoriesState> emit) async {
    final current = state is CategoriesLoaded ? (state as CategoriesLoaded).categories : const <FinanceCategory>[];
    emit(CategoriesLoaded(List.unmodifiable(current)));
    try {
      final categories = await categoryService.getUserCategories();
      emit(CategoriesLoaded(List.unmodifiable(categories)));
    } catch (e, st) {
      developer.log('Refresh categories error', error: e, stackTrace: st);
      emit(CategoriesOperationFailure(_mapErrorToMessage(e), current));
    }
  }

  Future<void> _onCategoriesUpdated(CategoriesUpdated event, Emitter<CategoriesState> emit) async {
    emit(CategoriesLoaded(List.unmodifiable(event.categories)));
  }

  String _mapErrorToMessage(Object e) {
    if (e is CouldnotFetchCategories) return 'Could not fetch categories, please try reloading the page';
    if (e is SocketException) return 'No Internet connection!, please try connecting to the internet';
    return e.toString();
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
