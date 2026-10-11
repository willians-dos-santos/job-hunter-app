import '../../domain/models/job_item.dart';
import '../../domain/models/user_job_interaction.dart';
import '../../domain/repositories/job_repository.dart';
import '../datasources/job_remote_datasource.dart';

/// Implementation of [IJobRepository] coordinating remote Supabase queries and mutations.
class JobRepository implements IJobRepository {
  const JobRepository(this._remoteDataSource);

  final IJobRemoteDataSource _remoteDataSource;

  @override
  Future<List<JobItem>> getJobs({
    int limit = 20,
    int offset = 0,
    String? statusFilter,
    String? query,
  }) {
    return _remoteDataSource.getJobs(
      limit: limit,
      offset: offset,
      statusFilter: statusFilter,
      query: query,
    );
  }

  @override
  Future<JobItem> getJobById(String id) {
    return _remoteDataSource.getJobById(id);
  }

  @override
  Future<void> updateJobStatus({
    required String jobId,
    required String newStatus,
  }) {
    return _remoteDataSource.updateJobStatus(
      jobId: jobId,
      newStatus: newStatus,
    );
  }

  @override
  Future<void> updateJobNotes({
    required String jobId,
    required String notes,
  }) {
    return _remoteDataSource.updateJobNotes(
      jobId: jobId,
      notes: notes,
    );
  }

  @override
  Future<void> toggleJobArchived({
    required String jobId,
    required bool isArchived,
  }) {
    return _remoteDataSource.toggleJobArchived(
      jobId: jobId,
      isArchived: isArchived,
    );
  }

  @override
  Future<void> updateJobInteraction(UserJobInteraction interaction) {
    return _remoteDataSource.upsertInteraction(interaction);
  }
}

/// Backwards-compatible aliases
typedef JobRepositoryImpl = JobRepository;
typedef JobsRepositoryImpl = JobRepository;
