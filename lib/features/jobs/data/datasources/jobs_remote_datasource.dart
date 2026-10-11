import '../../domain/models/job_item.dart';
import '../../domain/models/user_job_interaction.dart';

/// Contract for remote Supabase queries and mutations on jobs.
abstract class JobsRemoteDataSource {
  /// Queries the `v_user_jobs` view.
  Future<List<JobItem>> fetchJobs({int limit = 50, int offset = 0});

  /// Queries a single job from `v_user_jobs`.
  Future<JobItem?> fetchJobById(String jobId);

  /// Upserts user interaction into `user_job_interactions`.
  Future<void> upsertInteraction(UserJobInteraction interaction);
}
