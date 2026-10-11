import '../models/job_item.dart';
import '../models/user_job_interaction.dart';

/// Contract for accessing and manipulating job listings and user interactions.
abstract class JobsRepository {
  /// Fetches a list of enriched job items from `v_user_jobs`.
  Future<List<JobItem>> getJobs({int limit = 50, int offset = 0});

  /// Fetches a single job item by its [jobId].
  Future<JobItem?> getJobById(String jobId);

  /// Saves or updates the user interaction (funnel stage, notes) on a job.
  Future<void> updateJobInteraction(UserJobInteraction interaction);
}
