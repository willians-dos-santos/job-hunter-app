/// Keys for reading configuration values from environment variables.
abstract final class EnvConstants {
  /// Supabase project URL key.
  static const String supabaseUrl = 'SUPABASE_URL';

  /// Supabase public anonymous key.
  static const String supabaseAnonKey = 'SUPABASE_ANON_KEY';

  /// Supabase user ID key.
  static const String supabaseUserId = 'SUPABASE_USER_ID';

  /// Fallback default user ID key.
  static const String defaultUserId = 'DEFAULT_USER_ID';
}
