import '../models/search_config.dart';

/// Contract for managing user search and filter criteria.
abstract class SearchConfigsRepository {
  /// Fetches all search configurations from `search_configs`.
  Future<List<SearchConfig>> getConfigs();

  /// Adds a new search config.
  Future<void> addConfig(SearchConfig config);

  /// Toggles active status of a config.
  Future<void> toggleActive(String id, bool isActive);

  /// Deletes a config by its identifier.
  Future<void> deleteConfig(String id);
}
