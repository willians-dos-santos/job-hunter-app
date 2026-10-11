import '../../domain/models/job_item.dart';
import '../../domain/models/user_job_interaction.dart';
import '../../domain/repositories/jobs_repository.dart';
import '../datasources/jobs_remote_datasource.dart';

/// Implementation of [JobsRepository] coordinating remote Supabase datasource.
class JobsRepositoryImpl implements JobsRepository {
  const JobsRepositoryImpl(this._remoteDataSource);

  final JobsRemoteDataSource _remoteDataSource;

  @override
  Future<List<JobItem>> getJobs({int limit = 50, int offset = 0}) {
    return _remoteDataSource.fetchJobs(limit: limit, offset: offset);
  }

  @override
  Future<JobItem?> getJobById(String jobId) {
    return _remoteDataSource.fetchJobById(jobId);
  }

  @override
  Future<void> updateJobInteraction(UserJobInteraction interaction) {
    return _remoteDataSource.upsertInteraction(interaction);
  }
}
