import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:job_hunter_app/features/search_configs/domain/models/search_config.dart';
import 'package:job_hunter_app/features/search_configs/domain/models/search_config_category.dart';
import 'package:job_hunter_app/features/search_configs/domain/repositories/search_configs_repository.dart';
import 'package:job_hunter_app/features/search_configs/presentation/cubit/search_configs_cubit.dart';
import 'package:job_hunter_app/features/search_configs/presentation/cubit/search_configs_state.dart';

class MockSearchConfigsRepository extends Mock
    implements SearchConfigsRepository {}

class FakeSearchConfig extends Fake implements SearchConfig {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeSearchConfig());
  });

  late MockSearchConfigsRepository mockRepository;
  late SearchConfigsCubit cubit;

  const testConfig1 = SearchConfig(
    id: 'cfg-1',
    category: SearchConfigCategory.keyword,
    value: 'Flutter',
    isActive: true,
  );

  const testConfig2 = SearchConfig(
    id: 'cfg-2',
    category: SearchConfigCategory.excludedKeyword,
    value: 'Presencial',
    isActive: false,
  );

  const testConfig3 = SearchConfig(
    id: 'cfg-3',
    category: SearchConfigCategory.atsFilter,
    value: 'greenhouse',
    isActive: true,
  );

  const testConfig4 = SearchConfig(
    id: 'cfg-4',
    category: SearchConfigCategory.location,
    value: 'Remoto',
    isActive: true,
  );

  setUp(() {
    mockRepository = MockSearchConfigsRepository();
    cubit = SearchConfigsCubit(mockRepository);
  });

  tearDown(() {
    cubit.close();
  });

  group('SearchConfigsState & Helpers', () {
    test('SearchConfigsLoaded helper methods work correctly', () {
      final loaded = SearchConfigsLoaded([
        testConfig1,
        testConfig2,
        testConfig3,
        testConfig4,
      ]);

      expect(loaded.activeCount, 3);
      expect(loaded.isEmpty, isFalse);
      expect(
        loaded.getByCategory(SearchConfigCategory.keyword),
        [testConfig1],
      );
      expect(
        loaded.getByCategory(SearchConfigCategory.excludedKeyword),
        [testConfig2],
      );
      expect(
        loaded.getByCategory(SearchConfigCategory.atsFilter),
        [testConfig3],
      );
      expect(
        loaded.getByCategory(SearchConfigCategory.location),
        [testConfig4],
      );
      expect(
        loaded.getByCategory(SearchConfigCategory.company),
        isEmpty,
      );
    });

    test('SearchConfigsLoaded copyWith works correctly', () {
      final loaded = SearchConfigsLoaded([testConfig1]);
      final updated = loaded.copyWith(actionMessage: 'Adicionado com sucesso');

      expect(updated.actionMessage, 'Adicionado com sucesso');
      expect(updated.configs, [testConfig1]);

      final cleared = updated.copyWith(clearActionMessage: true);
      expect(cleared.actionMessage, isNull);
    });

    test('States are Equatable', () {
      expect(
        const SearchConfigsInitial(),
        const SearchConfigsInitial(),
      );
      expect(
        const SearchConfigsLoading(),
        const SearchConfigsLoading(),
      );
      expect(
        SearchConfigsLoaded([testConfig1]),
        SearchConfigsLoaded([testConfig1]),
      );
      expect(
        const SearchConfigsError('Erro A'),
        const SearchConfigsError('Erro A'),
      );
      expect(
        const SearchConfigsError('Erro A') == const SearchConfigsError('Erro B'),
        isFalse,
      );
    });
  });

  group('SearchConfigsCubit', () {
    test('initial state is SearchConfigsInitial', () {
      expect(cubit.state, const SearchConfigsInitial());
      expect(cubit.repository, mockRepository);
    });

    test('loadConfigs emits [SearchConfigsLoading, SearchConfigsLoaded] on success',
        () async {
      when(() => mockRepository.getConfigs())
          .thenAnswer((_) async => [testConfig1, testConfig2]);

      final states = <SearchConfigsState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.loadConfigs();
      await Future<void>.delayed(Duration.zero);

      expect(states, [
        const SearchConfigsLoading(),
        SearchConfigsLoaded([testConfig1, testConfig2]),
      ]);

      verify(() => mockRepository.getConfigs()).called(1);
      await subscription.cancel();
    });

    test('loadConfigs emits [SearchConfigsLoading, SearchConfigsError] on failure',
        () async {
      when(() => mockRepository.getConfigs())
          .thenThrow(Exception('Falha de conexão com o banco'));

      final states = <SearchConfigsState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.loadConfigs();
      await Future<void>.delayed(Duration.zero);

      expect(states.length, 2);
      expect(states.first, const SearchConfigsLoading());
      expect(states.last, isA<SearchConfigsError>());
      expect(
        (states.last as SearchConfigsError).message,
        contains('Erro ao carregar critérios de busca'),
      );

      verify(() => mockRepository.getConfigs()).called(1);
      await subscription.cancel();
    });

    test('addConfig calls repository.addConfig and reloads configs', () async {
      when(() => mockRepository.addConfig(any()))
          .thenAnswer((_) async {});
      when(() => mockRepository.getConfigs())
          .thenAnswer((_) async => [testConfig1]);

      final states = <SearchConfigsState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.addConfig(testConfig1);
      await Future<void>.delayed(Duration.zero);

      verify(() => mockRepository.addConfig(testConfig1)).called(1);
      verify(() => mockRepository.getConfigs()).called(1);

      expect(states.contains(SearchConfigsLoaded([testConfig1])), isTrue);
      await subscription.cancel();
    });

    test('addConfig trims value and ignores empty text', () async {
      const emptyConfig = SearchConfig(
        id: '',
        category: SearchConfigCategory.keyword,
        value: '   ',
        isActive: true,
      );

      await cubit.addConfig(emptyConfig);

      verifyNever(() => mockRepository.addConfig(any()));
    });

    test('addConfig emits SearchConfigsError on repository failure', () async {
      when(() => mockRepository.addConfig(any()))
          .thenThrow(Exception('Falha ao inserir'));

      final states = <SearchConfigsState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.addConfig(testConfig1);
      await Future<void>.delayed(Duration.zero);

      expect(states.last, isA<SearchConfigsError>());
      expect(
        (states.last as SearchConfigsError).message,
        contains('Erro ao adicionar critério'),
      );
      await subscription.cancel();
    });

    test('addTerm delegates correctly to addConfig and repository', () async {
      when(() => mockRepository.addConfig(any()))
          .thenAnswer((_) async {});
      when(() => mockRepository.getConfigs())
          .thenAnswer((_) async => [testConfig1]);

      await cubit.addTerm(
        category: SearchConfigCategory.keyword,
        value: '  Flutter  ',
      );

      verify(() => mockRepository.addConfig(any(that: predicate<SearchConfig>((c) {
            return c.category == SearchConfigCategory.keyword &&
                c.value == 'Flutter' &&
                c.isActive == true;
          })))).called(1);
    });

    test('addTerm ignores empty or whitespace string', () async {
      await cubit.addTerm(
        category: SearchConfigCategory.keyword,
        value: '   ',
      );

      verifyNever(() => mockRepository.addConfig(any()));
    });

    test('toggleActive calls repository.toggleActive and reloads', () async {
      when(() => mockRepository.toggleActive(any(), any()))
          .thenAnswer((_) async {});
      when(() => mockRepository.getConfigs())
          .thenAnswer((_) async => [testConfig1.copyWith(isActive: false)]);

      await cubit.toggleActive('cfg-1', false);

      verify(() => mockRepository.toggleActive('cfg-1', false)).called(1);
      verify(() => mockRepository.getConfigs()).called(1);
      expect(
        cubit.state,
        SearchConfigsLoaded([testConfig1.copyWith(isActive: false)]),
      );
    });

    test('toggleActive emits SearchConfigsError on failure', () async {
      when(() => mockRepository.toggleActive(any(), any()))
          .thenThrow(Exception('Erro de rede'));

      await cubit.toggleActive('cfg-1', false);

      expect(cubit.state, isA<SearchConfigsError>());
      expect(
        (cubit.state as SearchConfigsError).message,
        contains('Erro ao alterar status'),
      );
    });

    test('deleteConfig calls repository.deleteConfig and reloads', () async {
      when(() => mockRepository.deleteConfig(any()))
          .thenAnswer((_) async {});
      when(() => mockRepository.getConfigs())
          .thenAnswer((_) async => []);

      await cubit.deleteConfig('cfg-1');

      verify(() => mockRepository.deleteConfig('cfg-1')).called(1);
      verify(() => mockRepository.getConfigs()).called(1);
      expect(cubit.state, const SearchConfigsLoaded([]));
    });

    test('deleteConfig emits SearchConfigsError on failure', () async {
      when(() => mockRepository.deleteConfig(any()))
          .thenThrow(Exception('Erro ao excluir'));

      await cubit.deleteConfig('cfg-1');

      expect(cubit.state, isA<SearchConfigsError>());
      expect(
        (cubit.state as SearchConfigsError).message,
        contains('Erro ao excluir critério'),
      );
    });
  });
}
