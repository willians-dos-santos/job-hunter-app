/// Global application and database constants.
abstract final class AppConstants {
  /// Name of the application.
  static const String appName = 'Job Hunter';

  /// Supabase View containing enriched user job listings.
  static const String userJobsView = 'v_user_jobs';

  /// Supabase View containing triage inbox (uninteracted vacancies for the current user).
  static const String newJobsView = 'v_new_jobs';

  /// Supabase View containing active pipeline jobs ('applied', 'interviewing', 'offer', 'rejected').
  static const String activePipelineJobsView = 'v_active_pipeline_jobs';

  /// Supabase Table storing search and filter criteria.
  static const String searchConfigsTable = 'search_configs';

  /// Supabase Table storing user job interactions (applications, stages, notes).
  static const String userJobInteractionsTable = 'user_job_interactions';

  /// Default pagination limit for triage new jobs inbox.
  static const int newJobsPageSize = 20;

  /// Default pagination limit for job lists.
  static const int defaultPageSize = 25;
}
