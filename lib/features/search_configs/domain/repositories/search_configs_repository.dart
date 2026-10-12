import '../models/search_config.dart';

/// Contract for managing user search and filter criteria in `public.search_configs`.
abstract class SearchConfigsRepository {
  /// Fetches all search configurations from `search_configs`.
  Future<List<SearchConfig>> getConfigs({String? userId});

  /// Adds a new search config.
  Future<void> addConfig(SearchConfig config, {String? userId});

  /// Toggles active status of a config.
  Future<void> toggleActive(String id, bool isActive, {String? userId});

  /// Deletes a config by its identifier.
  Future<void> deleteConfig(String id, {String? userId});
}
