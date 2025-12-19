import 'package:finance_frontend/features/transactions/presentation/cubits/report_analytics_cubit.dart';
import 'package:finance_frontend/features/transactions/presentation/views/report_and_anlytics_view.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Reportandanlyticswrappr extends ConsumerWidget {
  const Reportandanlyticswrappr({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BlocProvider.value(
      value: context.read<ReportAnalyticsCubit>(),
      child: ReportAndAnlyticsView(),
    );
  }
}
