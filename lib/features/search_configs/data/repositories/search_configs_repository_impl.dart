import '../../domain/models/search_config.dart';
import '../../domain/repositories/search_configs_repository.dart';
import '../datasources/search_configs_remote_datasource.dart';

/// Implementation of [SearchConfigsRepository] coordinating remote Supabase datasource.
class SearchConfigsRepositoryImpl implements SearchConfigsRepository {
  const SearchConfigsRepositoryImpl(this._remoteDataSource);

  final SearchConfigsRemoteDataSource _remoteDataSource;

  @override
  Future<List<SearchConfig>> getConfigs() {
    return _remoteDataSource.fetchConfigs();
  }

  @override
  Future<void> addConfig(SearchConfig config) {
    return _remoteDataSource.insertConfig(config);
  }

  @override
  Future<void> toggleActive(String id, bool isActive) {
    return _remoteDataSource.updateActive(id, isActive);
  }

  @override
  Future<void> deleteConfig(String id) {
    return _remoteDataSource.removeConfig(id);
  }
}
