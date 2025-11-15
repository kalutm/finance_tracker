import 'package:finance_frontend/features/categories/data/services/finance_category_service.dart';
import 'package:finance_frontend/features/categories/presentation/blocs/categories/categories_bloc.dart';
import 'package:finance_frontend/features/categories/presentation/blocs/category_form/category_form_bloc.dart';
import 'package:finance_frontend/features/categories/presentation/views/categories_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CategoriesWrapper extends StatelessWidget {
  const CategoriesWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(
          value: context.read<CategoriesBloc>(),
        ),
        BlocProvider(create: (context) => CategoryFormBloc(FinanceCategoryService())),
      ],
      child: const CategoriesView(),
    );
  }
}
