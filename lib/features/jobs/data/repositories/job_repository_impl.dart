import '../../../../core/services/env_config.dart';
import '../../domain/models/job_item.dart';
import '../../domain/models/user_job_interaction.dart';
import '../../domain/repositories/job_repository.dart';
import '../datasources/job_remote_datasource.dart';

/// Implementation of [IJobRepository] coordinating remote Supabase queries and mutations.
class JobRepository implements IJobRepository {
  JobRepository([
    IJobRemoteDataSource? remoteDataSource,
    String? userId,
  ])  : _remoteDataSource =
            remoteDataSource ?? JobRemoteDataSource(null, userId),
        _configuredUserId = userId;

  final IJobRemoteDataSource _remoteDataSource;
  final String? _configuredUserId;

  /// Effective user ID resolved from explicit injection or [EnvConfig.supabaseUserId].
  String? get currentUserId {
    final configured = _configuredUserId?.trim();
    if (configured != null && configured.isNotEmpty) {
      return configured;
    }
    if (EnvConfig.isInitialized) {
      return EnvConfig.supabaseUserId;
    }
    return null;
  }

  @override
  Future<List<JobItem>> getJobs({
    int limit = 20,
    int offset = 0,
    String? statusFilter,
    String? query,
    String? userId,
  }) {
    return _remoteDataSource.getJobs(
      limit: limit,
      offset: offset,
      statusFilter: statusFilter,
      query: query,
      userId: userId ?? currentUserId,
    );
  }

  @override
  Future<List<JobItem>> getArchivedJobs({
    int limit = 50,
    int offset = 0,
    String? userId,
  }) {
    return _remoteDataSource.getArchivedJobs(
      limit: limit,
      offset: offset,
      userId: userId ?? currentUserId,
    );
  }

  @override
  Future<JobItem> getJobById(String id, {String? userId}) {
    return _remoteDataSource.getJobById(
      id,
      userId: userId ?? currentUserId,
    );
  }

  @override
  Future<void> updateJobStatus({
    required String jobId,
    required String newStatus,
    String? userId,
  }) {
    return _remoteDataSource.updateJobStatus(
      jobId: jobId,
      newStatus: newStatus,
      userId: userId ?? currentUserId,
    );
  }

  @override
  Future<void> updateJobNotes({
    required String jobId,
    required String notes,
    String? userId,
  }) {
    return _remoteDataSource.updateJobNotes(
      jobId: jobId,
      notes: notes,
      userId: userId ?? currentUserId,
    );
  }

  @override
  Future<void> toggleJobArchived({
    required String jobId,
    required bool isArchived,
    String? userId,
  }) {
    return _remoteDataSource.toggleJobArchived(
      jobId: jobId,
      isArchived: isArchived,
      userId: userId ?? currentUserId,
    );
  }

  @override
  Future<void> updateJobInteraction(
    UserJobInteraction interaction, {
    String? userId,
  }) {
    final effectiveUserId = userId ?? currentUserId;
    final interactionWithUser =
        (interaction.userId == null && effectiveUserId != null)
            ? interaction.copyWith(userId: effectiveUserId)
            : interaction;

    return _remoteDataSource.upsertInteraction(
      interactionWithUser,
      userId: effectiveUserId,
    );
  }
}

/// Backwards-compatible aliases
typedef JobRepositoryImpl = JobRepository;
typedef JobsRepositoryImpl = JobRepository;
