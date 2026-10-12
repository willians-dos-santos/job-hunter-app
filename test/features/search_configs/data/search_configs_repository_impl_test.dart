import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:job_hunter_app/features/search_configs/data/datasources/search_configs_remote_datasource.dart';
import 'package:job_hunter_app/features/search_configs/data/repositories/search_configs_repository_impl.dart';
import 'package:job_hunter_app/features/search_configs/domain/models/search_config.dart';
import 'package:job_hunter_app/features/search_configs/domain/models/search_config_category.dart';

class MockSearchConfigsRemoteDataSource extends Mock
    implements SearchConfigsRemoteDataSource {}

class FakeSearchConfig extends Fake implements SearchConfig {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeSearchConfig());
  });

  late MockSearchConfigsRemoteDataSource mockRemoteDataSource;
  late SearchConfigsRepositoryImpl repository;

  const testConfig = SearchConfig(
    id: 'cfg-1',
    category: SearchConfigCategory.keyword,
    value: 'Flutter',
    isActive: true,
  );

  setUp(() {
    mockRemoteDataSource = MockSearchConfigsRemoteDataSource();
    repository = SearchConfigsRepositoryImpl(mockRemoteDataSource);
  });

  group('SearchConfigsRepositoryImpl', () {
    test('getConfigs delegates to remoteDataSource.fetchConfigs', () async {
      when(() => mockRemoteDataSource.fetchConfigs(userId: any(named: 'userId')))
          .thenAnswer((_) async => [testConfig]);

      final result = await repository.getConfigs();

      expect(result, [testConfig]);
      verify(() => mockRemoteDataSource.fetchConfigs(userId: null)).called(1);
    });

    test('addConfig delegates to remoteDataSource.insertConfig', () async {
      when(() => mockRemoteDataSource.insertConfig(any(), userId: any(named: 'userId')))
          .thenAnswer((_) async {});

      await repository.addConfig(testConfig);

      verify(() => mockRemoteDataSource.insertConfig(testConfig, userId: null))
          .called(1);
    });

    test('toggleActive delegates to remoteDataSource.updateActive', () async {
      when(() => mockRemoteDataSource.updateActive(any(), any(), userId: any(named: 'userId')))
          .thenAnswer((_) async {});

      await repository.toggleActive('cfg-1', false);

      verify(() => mockRemoteDataSource.updateActive('cfg-1', false, userId: null))
          .called(1);
    });

    test('deleteConfig delegates to remoteDataSource.removeConfig', () async {
      when(() => mockRemoteDataSource.removeConfig(any(), userId: any(named: 'userId')))
          .thenAnswer((_) async {});

      await repository.deleteConfig('cfg-1');

      verify(() => mockRemoteDataSource.removeConfig('cfg-1', userId: null))
          .called(1);
    });
  });
}
