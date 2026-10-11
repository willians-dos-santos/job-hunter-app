import '../models/job_item.dart';
import '../models/user_job_interaction.dart';

/// Contract for accessing and manipulating job listings and user interactions.
abstract class IJobRepository {
  /// Fetches a list of enriched job items from `v_user_jobs`.
  ///
  /// Supports offset-based pagination, funnel status filter, text query search
  /// across title or company name, optional user filter, and defaults to descending order by publication date.
  Future<List<JobItem>> getJobs({
    int limit = 20,
    int offset = 0,
    String? statusFilter,
    String? query,
    String? userId,
  });

  /// Fetches a detailed job item by its [id].
  ///
  /// Throws [JobNotFoundFailure] if not found, or [JobFetchFailure] on query error.
  Future<JobItem> getJobById(String id, {String? userId});

  /// Updates or inserts the candidate funnel status for [jobId].
  ///
  /// Supported statuses: `new`, `applied`, `interview`, `offer`, `rejected`.
  Future<void> updateJobStatus({
    required String jobId,
    required String newStatus,
    String? userId,
  });

  /// Updates or inserts personal notes for [jobId].
  Future<void> updateJobNotes({
    required String jobId,
    required String notes,
    String? userId,
  });

  /// Toggles whether [jobId] is marked as archived/discarded.
  Future<void> toggleJobArchived({
    required String jobId,
    required bool isArchived,
    String? userId,
  });

  /// Saves or updates the complete user interaction on a job.
  Future<void> updateJobInteraction(
    UserJobInteraction interaction, {
    String? userId,
  });
}

/// Backwards-compatible alias for [IJobRepository].
typedef JobsRepository = IJobRepository;
