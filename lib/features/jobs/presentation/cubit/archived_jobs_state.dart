import 'package:flutter/foundation.dart';

import '../../domain/models/job_item.dart';

/// Base state for the archived jobs management flow.
@immutable
sealed class ArchivedJobsState {
  const ArchivedJobsState();
}

/// Initial state before any load request is issued.
class ArchivedJobsInitial extends ArchivedJobsState {
  const ArchivedJobsInitial();
}

/// State emitted while fetching archived jobs from the repository.
class ArchivedJobsLoading extends ArchivedJobsState {
  const ArchivedJobsLoading();
}

/// State emitted when archived jobs have been loaded successfully.
class ArchivedJobsLoaded extends ArchivedJobsState {
  const ArchivedJobsLoaded(
    this.jobs, {
    this.errorMessage,
    this.successMessage,
  });

  /// The list of currently archived job vacancies.
  final List<JobItem> jobs;

  /// Transient error message (e.g. on restore mutation failure).
  final String? errorMessage;

  /// Transient success feedback message.
  final String? successMessage;

  ArchivedJobsLoaded copyWith({
    List<JobItem>? jobs,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? successMessage,
    bool clearSuccessMessage = false,
  }) {
    return ArchivedJobsLoaded(
      jobs ?? this.jobs,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearSuccessMessage ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ArchivedJobsLoaded &&
        listEquals(other.jobs, jobs) &&
        other.errorMessage == errorMessage &&
        other.successMessage == successMessage;
  }

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(jobs), errorMessage, successMessage);
}

/// State emitted when fetching archived jobs fails completely.
class ArchivedJobsError extends ArchivedJobsState {
  const ArchivedJobsError(this.message);

  final String message;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ArchivedJobsError && other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}
