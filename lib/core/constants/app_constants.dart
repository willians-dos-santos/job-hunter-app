/// Global application and database constants.
abstract final class AppConstants {
  /// Name of the application.
  static const String appName = 'Job Hunter';

  /// Supabase Table containing canonical scraped vacancies.
  static const String jobsTable = 'jobs';

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

  /// Supabase Table storing FCM push notification device tokens.
  static const String userDeviceTokensTable = 'user_device_tokens';

  /// Notification channel ID for local and FCM push notifications.
  static const String notificationChannelId = 'job_hunter_channel';

  /// Notification channel name.
  static const String notificationChannelName = 'Vagas e Notificações';

  /// Default pagination limit for triage new jobs inbox.
  static const int newJobsPageSize = 20;

  /// Default pagination limit for job lists.
  static const int defaultPageSize = 25;
}
