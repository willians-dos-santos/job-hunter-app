/// Global application and database constants.
abstract final class AppConstants {
  /// Name of the application.
  static const String appName = 'Job Hunter';

  /// Supabase View containing enriched user job listings.
  static const String userJobsView = 'v_user_jobs';

  /// Supabase Table storing search and filter criteria.
  static const String searchConfigsTable = 'search_configs';

  /// Supabase Table storing user job interactions (applications, stages, notes).
  static const String userJobInteractionsTable = 'user_job_interactions';

  /// Default pagination limit for job lists.
  static const int defaultPageSize = 25;
}
