import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:job_hunter_app/core/theme/app_theme.dart';
import 'package:job_hunter_app/features/search_configs/domain/models/search_config.dart';
import 'package:job_hunter_app/features/search_configs/domain/models/search_config_category.dart';
import 'package:job_hunter_app/features/search_configs/domain/repositories/search_configs_repository.dart';
import 'package:job_hunter_app/features/search_configs/presentation/cubit/search_configs_cubit.dart';
import 'package:job_hunter_app/features/search_configs/presentation/cubit/search_configs_state.dart';
import 'package:job_hunter_app/features/search_configs/presentation/pages/search_configs_screen.dart';

class MockSearchConfigsRepository extends Mock
    implements SearchConfigsRepository {}

class MockSearchConfigsCubit extends Mock implements SearchConfigsCubit {}

class FakeSearchConfig extends Fake implements SearchConfig {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeSearchConfig());
    registerFallbackValue(SearchConfigCategory.keyword);
  });

  late MockSearchConfigsCubit mockCubit;
  late StreamController<SearchConfigsState> stateController;

  const testKeyword1 = SearchConfig(
    id: 'cfg-k1',
    category: SearchConfigCategory.keyword,
    value: 'Flutter',
    isActive: true,
  );

  const testKeyword2 = SearchConfig(
    id: 'cfg-k2',
    category: SearchConfigCategory.keyword,
    value: 'Dart',
    isActive: false,
  );

  const testExcluded = SearchConfig(
    id: 'cfg-e1',
    category: SearchConfigCategory.excludedKeyword,
    value: 'Presencial',
    isActive: true,
  );

  const testAts = SearchConfig(
    id: 'cfg-a1',
    category: SearchConfigCategory.atsFilter,
    value: 'greenhouse',
    isActive: true,
  );

  const testLocation = SearchConfig(
    id: 'cfg-l1',
    category: SearchConfigCategory.location,
    value: 'Remoto',
    isActive: true,
  );

  final testConfigsList = [
    testKeyword1,
    testKeyword2,
    testExcluded,
    testAts,
    testLocation,
  ];

  setUp(() {
    mockCubit = MockSearchConfigsCubit();
    stateController = StreamController<SearchConfigsState>.broadcast();

    when(() => mockCubit.state).thenReturn(const SearchConfigsInitial());
    when(() => mockCubit.stream).thenAnswer((_) => stateController.stream);
    when(() => mockCubit.loadConfigs()).thenAnswer((_) async {});
    when(() => mockCubit.addTerm(
          category: any(named: 'category'),
          value: any(named: 'value'),
        )).thenAnswer((_) async {});
    when(() => mockCubit.toggleActive(any(), any())).thenAnswer((_) async {});
    when(() => mockCubit.deleteConfig(any())).thenAnswer((_) async {});
  });

  tearDown(() async {
    await stateController.close();
  });

  Widget buildSubject({SearchConfigsCubit? cubit}) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: SearchConfigsScreen(cubit: cubit ?? mockCubit),
    );
  }

  group('SearchConfigsScreen Widget Tests', () {
    testWidgets('renders AppBar with title and SEARCH-CONFIGS tag',
        (tester) async {
      when(() => mockCubit.state)
          .thenReturn(SearchConfigsLoaded(testConfigsList));

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('SEARCH-CONFIGS'), findsOneWidget);
      expect(find.text('Critérios de Busca'), findsOneWidget);
      expect(find.byTooltip('Recarregar critérios'), findsOneWidget);
      expect(find.byTooltip('Voltar'), findsOneWidget);
    });

    testWidgets('renders loading indicator when state is SearchConfigsLoading',
        (tester) async {
      when(() => mockCubit.state).thenReturn(const SearchConfigsLoading());

      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets(
        'renders error card on SearchConfigsError and retries on button tap',
        (tester) async {
      when(() => mockCubit.state)
          .thenReturn(const SearchConfigsError('Erro de conexão ao banco'));

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Falha ao carregar critérios'), findsOneWidget);
      expect(find.text('Erro de conexão ao banco'), findsOneWidget);
      expect(find.text('Tentar Novamente'), findsOneWidget);

      await tester.tap(find.text('Tentar Novamente'));
      await tester.pumpAndSettle();

      verify(() => mockCubit.loadConfigs()).called(1);
    });

    testWidgets('renders all 4 category groups and their chips when loaded',
        (tester) async {
      when(() => mockCubit.state)
          .thenReturn(SearchConfigsLoaded(testConfigsList));

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Category titles
      expect(find.text('Palavra-chave'), findsWidgets);
      expect(find.text('Termo Excluído'), findsWidgets);
      expect(find.text('Filtro ATS'), findsWidgets);
      expect(find.text('Localização'), findsWidgets);

      // Chips
      expect(find.text('Flutter'), findsOneWidget);
      expect(find.text('Dart'), findsOneWidget);
      expect(find.text('Presencial'), findsOneWidget);
      expect(find.text('greenhouse'), findsOneWidget);
      expect(find.text('Remoto'), findsOneWidget);

      // Summary counter: 4 of 5 active
      expect(find.text('4 / 5 ativos'), findsOneWidget);
    });

    testWidgets('renders empty placeholder for categories with no terms',
        (tester) async {
      when(() => mockCubit.state)
          .thenReturn(const SearchConfigsLoaded([testKeyword1]));

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Flutter'), findsOneWidget);
      expect(
        find.text('Nenhum termo cadastrado nesta categoria.'),
        findsNWidgets(3),
      );
    });

    testWidgets('tapping a chip calls cubit.toggleActive with inverted isActive',
        (tester) async {
      when(() => mockCubit.state)
          .thenReturn(SearchConfigsLoaded(testConfigsList));

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // testKeyword1 is active (true) -> tap toggles to false
      final flutterChip = find.byKey(const Key('chip_keyword_Flutter'));
      expect(flutterChip, findsOneWidget);

      await tester.tap(flutterChip);
      await tester.pumpAndSettle();

      verify(() => mockCubit.toggleActive('cfg-k1', false)).called(1);

      // testKeyword2 is inactive (false) -> tap toggles to true
      final dartChip = find.byKey(const Key('chip_keyword_Dart'));
      expect(dartChip, findsOneWidget);

      await tester.tap(dartChip);
      await tester.pumpAndSettle();

      verify(() => mockCubit.toggleActive('cfg-k2', true)).called(1);
    });

    testWidgets('tapping delete icon on chip calls cubit.deleteConfig',
        (tester) async {
      when(() => mockCubit.state)
          .thenReturn(SearchConfigsLoaded(testConfigsList));

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      final deleteBtn = find.byKey(const Key('delete_keyword_Flutter'));
      expect(deleteBtn, findsOneWidget);

      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      verify(() => mockCubit.deleteConfig('cfg-k1')).called(1);
    });

    testWidgets('adds new term via input form with selected category',
        (tester) async {
      when(() => mockCubit.state)
          .thenReturn(SearchConfigsLoaded(testConfigsList));

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Seleciona a categoria 'Localização'
      final locChoiceChip = find.byKey(const Key('category_chip_location'));
      expect(locChoiceChip, findsOneWidget);
      await tester.tap(locChoiceChip);
      await tester.pumpAndSettle();

      // Digita no campo de texto
      final inputFinder = find.byKey(const Key('add_term_input'));
      expect(inputFinder, findsOneWidget);
      await tester.enterText(inputFinder, 'Belo Horizonte');
      await tester.pumpAndSettle();

      // Clica em 'Adicionar'
      final addBtn = find.byKey(const Key('add_term_button'));
      expect(addBtn, findsOneWidget);
      await tester.tap(addBtn);
      await tester.pumpAndSettle();

      verify(() => mockCubit.addTerm(
            category: SearchConfigCategory.location,
            value: 'Belo Horizonte',
          )).called(1);

      // Campo de texto limpo após submit
      final inputWidget = tester.widget<TextField>(inputFinder);
      expect(inputWidget.controller?.text, isEmpty);
    });

    testWidgets('tapping refresh button in AppBar calls cubit.loadConfigs',
        (tester) async {
      when(() => mockCubit.state)
          .thenReturn(SearchConfigsLoaded(testConfigsList));

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Recarregar critérios'));
      await tester.pumpAndSettle();

      verify(() => mockCubit.loadConfigs()).called(1);
    });

    testWidgets(
        'adapts safely without RenderFlex overflow when vertical height is reduced (virtual keyboard simulation)',
        (tester) async {
      when(() => mockCubit.state)
          .thenReturn(SearchConfigsLoaded(testConfigsList));

      // Simula viewport padrão (tablet/desktop)
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Reduz drasticamente a altura simulando abertura do teclado virtual
      tester.view.physicalSize = const Size(800, 360);
      await tester.pumpAndSettle();

      // Não deve lançar nenhuma exceção de overflow
      expect(tester.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('tapping back button in AppBar pops route', (tester) async {
      when(() => mockCubit.state)
          .thenReturn(SearchConfigsLoaded(testConfigsList));

      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => Navigator.push(
                ctx,
                MaterialPageRoute(
                  builder: (_) => SearchConfigsScreen(cubit: mockCubit),
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(SearchConfigsScreen), findsOneWidget);

      await tester.tap(find.byTooltip('Voltar'));
      await tester.pumpAndSettle();

      expect(find.byType(SearchConfigsScreen), findsNothing);
    });
  });
}
