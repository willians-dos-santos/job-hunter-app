import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../jobs/domain/repositories/job_repository.dart';
import '../../domain/models/dashboard_metrics.dart';
import 'analytics_dashboard_state.dart';

/// Cubit orchestrating loading, aggregation and state management for [AnalyticsDashboardScreen].
class AnalyticsDashboardCubit extends Cubit<AnalyticsDashboardState> {
  AnalyticsDashboardCubit(this._repository)
      : super(const AnalyticsDashboardInitial());

  final IJobRepository _repository;

  /// Exposes the underlying repository.
  IJobRepository get repository => _repository;

  /// Loads jobs from `v_user_jobs` and calculates executive funnel metrics.
  Future<void> loadMetrics({int limit = 500}) async {
    emit(const AnalyticsDashboardLoading());
    try {
      final jobs = await _repository.getJobs(limit: limit);
      final metrics = DashboardMetrics.fromJobs(jobs);
      emit(AnalyticsDashboardLoaded(
        metrics: metrics,
        jobs: jobs,
      ));
    } catch (e) {
      emit(AnalyticsDashboardError('Erro ao carregar métricas: $e'));
    }
  }

  /// Refreshes the metrics from the repository.
  Future<void> refresh() => loadMetrics();
}
