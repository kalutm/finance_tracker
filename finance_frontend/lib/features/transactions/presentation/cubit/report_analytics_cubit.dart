import 'dart:async';

import 'package:finance_frontend/features/transactions/data/model/report_analytics.dart';
import 'package:finance_frontend/features/transactions/domain/service/transaction_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ReportAnalyticsCubit extends Cubit<ReportAnalytics> {
  final TransactionService transactionsService;
  StreamSubscription<ReportAnalytics>? _reportAnalyticsSub;
  ReportAnalyticsCubit(this.transactionsService) : super(ReportAnalytics()) {
    _reportAnalyticsSub = transactionsService.reportAnalyticsStream.listen((
      event,
    ) {
      emit(event);
    });
  }

  @override
  Future<void> close() {
    _reportAnalyticsSub?.cancel();
    return super.close();
  }
}
