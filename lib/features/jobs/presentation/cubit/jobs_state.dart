import 'package:flutter/foundation.dart';

import '../../domain/models/job_item.dart';
import '../../domain/models/job_status.dart';

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

/// State when jobs are successfully loaded and available for the Kanban board.
final class JobsLoaded extends JobsState {
  const JobsLoaded(
    this.jobs, {
    this.allJobs = const [],
    this.searchQuery,
    this.errorMessage,
  });

  /// Active list of jobs currently displayed (filtered by search query and non-archived).
  final List<JobItem> jobs;

  /// Base list of all active non-archived jobs before memory filtering.
  final List<JobItem> allJobs;

  /// Current text search query applied to [jobs], if any.
  final String? searchQuery;

  /// Optional error notification message from an optimistic action rollback.
  final String? errorMessage;

  /// Effective list of all jobs, defaulting to [jobs] if [allJobs] is empty.
  List<JobItem> get effectiveAllJobs => allJobs.isEmpty ? jobs : allJobs;

  /// Returns the subset of [jobs] matching the given funnel [status].
  List<JobItem> jobsByStatus(JobStatus status) {
    return jobs.where((job) => job.status == status).toList();
  }

  /// Creates a copy of [JobsLoaded] with updated properties.
  JobsLoaded copyWith({
    List<JobItem>? jobs,
    List<JobItem>? allJobs,
    String? searchQuery,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return JobsLoaded(
      jobs ?? this.jobs,
      allJobs: allJobs ?? effectiveAllJobs,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is JobsLoaded &&
        listEquals(other.jobs, jobs) &&
        listEquals(other.effectiveAllJobs, effectiveAllJobs) &&
        other.searchQuery == searchQuery &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(jobs),
        Object.hashAll(effectiveAllJobs),
        searchQuery,
        errorMessage,
      );
}

/// State when an unrecoverable error occurs while loading jobs.
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
