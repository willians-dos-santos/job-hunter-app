import '../../domain/models/search_config.dart';

/// Contract for remote operations on `search_configs` table in Supabase.
abstract class SearchConfigsRemoteDataSource {
  /// Fetches all search configs from Supabase.
  Future<List<SearchConfig>> fetchConfigs();

  /// Inserts a search config into Supabase.
  Future<void> insertConfig(SearchConfig config);

  /// Updates the `is_active` status of a search config.
  Future<void> updateActive(String id, bool isActive);

  /// Deletes a search config from Supabase.
  Future<void> removeConfig(String id);
}
