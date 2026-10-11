import 'package:flutter/foundation.dart';

import '../../domain/models/job_item.dart';

/// Base state for jobs presentation.
@immutable
sealed class JobsState {
  const JobsState();
}

/// Initial idle state.
final class JobsInitial extends JobsState {
  const JobsInitial();
}

/// State while fetching jobs.
final class JobsLoading extends JobsState {
  const JobsLoading();
}

/// State when jobs are successfully loaded.
final class JobsLoaded extends JobsState {
  const JobsLoaded(this.jobs);

  final List<JobItem> jobs;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is JobsLoaded && listEquals(other.jobs, jobs);
  }

  @override
  int get hashCode => jobs.hashCode;
}

/// State when an error occurs while handling jobs.
final class JobsError extends JobsState {
  const JobsError(this.message);

  final String message;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is JobsError && other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}
