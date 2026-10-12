import '../../domain/models/search_config.dart';
import '../../domain/repositories/search_configs_repository.dart';
import '../datasources/search_configs_remote_datasource.dart';

/// Implementation of [SearchConfigsRepository] coordinating remote Supabase datasource.
class SearchConfigsRepositoryImpl implements SearchConfigsRepository {
  SearchConfigsRepositoryImpl([SearchConfigsRemoteDataSource? remoteDataSource])
      : _remoteDataSource =
            remoteDataSource ?? SearchConfigsRemoteDataSourceImpl();

  final SearchConfigsRemoteDataSource _remoteDataSource;

  @override
  Future<List<SearchConfig>> getConfigs({String? userId}) {
    return _remoteDataSource.fetchConfigs(userId: userId);
  }

  @override
  Future<void> addConfig(SearchConfig config, {String? userId}) {
    return _remoteDataSource.insertConfig(config, userId: userId);
  }

  @override
  Future<void> toggleActive(String id, bool isActive, {String? userId}) {
    return _remoteDataSource.updateActive(id, isActive, userId: userId);
  }

  @override
  Future<void> deleteConfig(String id, {String? userId}) {
    return _remoteDataSource.removeConfig(id, userId: userId);
  }
}
