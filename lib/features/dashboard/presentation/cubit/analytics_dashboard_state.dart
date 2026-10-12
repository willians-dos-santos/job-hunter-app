import 'package:flutter/foundation.dart';

import '../../../jobs/domain/models/job_item.dart';
import '../../domain/models/dashboard_metrics.dart';

/// Base state for the analytics dashboard flow.
@immutable
sealed class AnalyticsDashboardState {
  const AnalyticsDashboardState();
}

/// Initial state before analytics data is requested.
class AnalyticsDashboardInitial extends AnalyticsDashboardState {
  const AnalyticsDashboardInitial();
}

/// State emitted while loading and aggregating metrics from the repository.
class AnalyticsDashboardLoading extends AnalyticsDashboardState {
  const AnalyticsDashboardLoading();
}

/// State emitted when metrics have been successfully aggregated and computed.
class AnalyticsDashboardLoaded extends AnalyticsDashboardState {
  const AnalyticsDashboardLoaded({
    required this.metrics,
    required this.jobs,
    this.errorMessage,
  });

  /// Computed executive metrics.
  final DashboardMetrics metrics;

  /// Raw retrieved jobs list.
  final List<JobEntity> jobs;

  /// Optional transient notification message.
  final String? errorMessage;

  /// Whether the user has no vacancies registered in the funnel.
  bool get isEmpty => jobs.isEmpty;

  AnalyticsDashboardLoaded copyWith({
    DashboardMetrics? metrics,
    List<JobEntity>? jobs,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return AnalyticsDashboardLoaded(
      metrics: metrics ?? this.metrics,
      jobs: jobs ?? this.jobs,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AnalyticsDashboardLoaded &&
        other.metrics == metrics &&
        listEquals(other.jobs, jobs) &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode => Object.hash(metrics, Object.hashAll(jobs), errorMessage);
}

/// State emitted when loading fails due to network or repository errors.
class AnalyticsDashboardError extends AnalyticsDashboardState {
  const AnalyticsDashboardError(this.message);

  final String message;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AnalyticsDashboardError && other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}
