import 'package:finance_frontend/core/provider/providers.dart';
import 'package:finance_frontend/features/categories/presentation/blocs/categories/categories_bloc.dart';
import 'package:finance_frontend/features/categories/presentation/blocs/category_form/category_form_bloc.dart';
import 'package:finance_frontend/features/categories/presentation/views/categories_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CategoriesWrapper extends ConsumerWidget {
  const CategoriesWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: context.read<CategoriesBloc>()),
        BlocProvider(
          create:
              (context) => CategoryFormBloc(ref.read(categoryServiceProvider)),
        ),
      ],
      child: const CategoriesView(),
    );
  }
}
