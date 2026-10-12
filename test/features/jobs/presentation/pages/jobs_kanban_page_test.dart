import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:job_hunter_app/core/theme/app_theme.dart';
import 'package:job_hunter_app/core/theme/app_typography.dart';
import 'package:job_hunter_app/features/jobs/domain/models/job_item.dart';
import 'package:job_hunter_app/features/jobs/domain/models/job_status.dart';
import 'package:job_hunter_app/features/jobs/domain/repositories/jobs_repository.dart';
import 'package:job_hunter_app/features/jobs/presentation/cubit/jobs_cubit.dart';
import 'package:job_hunter_app/features/jobs/presentation/pages/archived_jobs_screen.dart';
import 'package:job_hunter_app/features/jobs/presentation/pages/jobs_kanban_page.dart';
import 'package:job_hunter_app/features/dashboard/presentation/pages/analytics_dashboard_screen.dart';
import 'package:job_hunter_app/features/search_configs/presentation/pages/search_configs_screen.dart';
import 'package:job_hunter_app/features/jobs/presentation/widgets/job_details_modal.dart';
import 'package:job_hunter_app/features/jobs/presentation/widgets/kanban_column.dart';
import 'package:job_hunter_app/features/jobs/presentation/widgets/kanban_error_view.dart';
import 'package:job_hunter_app/features/jobs/presentation/widgets/kanban_loading_skeleton.dart';
import 'package:job_hunter_app/features/search_configs/domain/repositories/search_configs_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockJobsRepository extends Mock implements JobsRepository {}

class MockSearchConfigsRepository extends Mock
    implements SearchConfigsRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    AppTypography.useSystemFonts = true;
  });

  tearDownAll(() {
    AppTypography.useSystemFonts = false;
  });

  late MockJobsRepository mockRepository;
  late JobsCubit cubit;

  final testJob1 = JobItem(
    jobId: '1',
    title: 'Senior Flutter Specialist',
    companyName: 'Apex Tech',
    platform: 'LinkedIn',
    jobUrl: 'https://example.com/1',
    status: JobStatus.newJob,
    createdAt: DateTime.now(),
  );

  final testJob2 = JobItem(
    jobId: '2',
    title: 'Lead Mobile Developer',
    companyName: 'Apex Tech',
    platform: 'Gupy',
    jobUrl: 'https://example.com/2',
    status: JobStatus.interview,
    createdAt: DateTime.now(),
  );

  final testJob3 = JobItem(
    jobId: '3',
    title: 'Product Engineer',
    companyName: 'Beta Inc',
    platform: 'Catho',
    jobUrl: 'https://example.com/3',
    status: JobStatus.offer,
    createdAt: DateTime.now(),
  );

  final testJobRemote = JobItem(
    jobId: '10',
    title: 'Flutter Developer Remote',
    companyName: 'Cloud Corp',
    platform: 'LinkedIn',
    jobUrl: 'https://example.com/10',
    status: JobStatus.newJob,
    location: 'Remoto',
    createdAt: DateTime.now(),
  );

  final testJobHybrid = JobItem(
    jobId: '20',
    title: 'Mobile Engineer Hybrid',
    companyName: 'Metro Inc',
    platform: 'Gupy',
    jobUrl: 'https://example.com/20',
    status: JobStatus.interview,
    location: 'Curitiba, PR (Híbrido)',
    createdAt: DateTime.now(),
  );

  final testJobOnSite = JobItem(
    jobId: '30',
    title: 'Software Engineer OnSite',
    companyName: 'Central Bank',
    platform: 'Catho',
    jobUrl: 'https://example.com/30',
    status: JobStatus.offer,
    location: 'Brasília, DF (Presencial)',
    createdAt: DateTime.now(),
  );

  setUp(() {
    mockRepository = MockJobsRepository();
    cubit = JobsCubit(mockRepository);
  });

  tearDown(() {
    cubit.close();
  });

  Widget buildSubject({
    JobsCubit? customCubit,
    SearchConfigsRepository? searchConfigsRepository,
  }) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: JobsKanbanPage(
        cubit: customCubit ?? cubit,
        searchConfigsRepository: searchConfigsRepository,
      ),
    );
  }

  group('JobsKanbanPage', () {
    testWidgets('renders KanbanLoadingSkeleton while loading', (tester) async {
      final completer = Completer<List<JobItem>>();
      when(() => mockRepository.getJobs()).thenAnswer((_) => completer.future);

      cubit.loadJobs();

      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.byType(KanbanLoadingSkeleton), findsOneWidget);

      completer.complete([testJob1]);
      await tester.pumpAndSettle();

      expect(find.byType(KanbanLoadingSkeleton), findsNothing);
      expect(find.byType(KanbanColumn), findsNWidgets(5));
    });

    testWidgets('renders KanbanErrorView on failure and allows retry',
        (tester) async {
      when(() => mockRepository.getJobs())
          .thenThrow(Exception('Falha de conexão com a view v_user_jobs'));

      await cubit.loadJobs();

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byType(KanbanErrorView), findsOneWidget);
      expect(find.text('Falha ao carregar o funil'), findsOneWidget);
      expect(find.text('Tentar novamente'), findsOneWidget);

      // Now prepare mock for retry success
      when(() => mockRepository.getJobs())
          .thenAnswer((_) async => [testJob1, testJob2]);

      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();

      expect(find.byType(KanbanErrorView), findsNothing);
      expect(find.byType(KanbanColumn), findsNWidgets(5));
      expect(find.text('Senior Flutter Specialist'), findsOneWidget);
    });

    testWidgets('renders all 5 funnel columns and filters jobs by search query',
        (tester) async {
      when(() => mockRepository.getJobs())
          .thenAnswer((_) async => [testJob1, testJob2, testJob3]);

      await cubit.loadJobs();

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Top title and total counter
      expect(find.text('Quadro de Vagas'), findsOneWidget);
      expect(find.text('3 vagas'), findsOneWidget);

      // All 5 column titles
      expect(find.text('Nova'), findsOneWidget);
      expect(find.text('Candidatado'), findsOneWidget);
      expect(find.text('Entrevista'), findsOneWidget);
      expect(find.text('Proposta'), findsOneWidget);
      expect(find.text('Rejeitada'), findsOneWidget);

      // Search field test
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      // Filter by 'Lead Mobile'
      await tester.enterText(searchField, 'Lead Mobile');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.text('Lead Mobile Developer'), findsOneWidget);
      expect(find.text('Senior Flutter Specialist'), findsNothing);
      expect(find.text('1 vagas'), findsOneWidget);

      // Clear search
      final clearButton = find.byIcon(Icons.clear_rounded);
      expect(clearButton, findsOneWidget);
      await tester.tap(clearButton);
      await tester.pumpAndSettle();

      expect(find.text('3 vagas'), findsOneWidget);
      expect(find.text('Senior Flutter Specialist'), findsOneWidget);
      expect(find.text('Lead Mobile Developer'), findsOneWidget);
    });

    testWidgets('displays SnackBar and reverts state when action rollback occurs',
        (tester) async {
      when(() => mockRepository.getJobs()).thenAnswer((_) async => [testJob1]);
      when(() => mockRepository.updateJobStatus(
            jobId: '1',
            newStatus: 'interviewing',
          )).thenThrow(Exception('Falha de escrita no Postgrest'));

      await cubit.loadJobs();

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Trigger move that will fail and rollback
      await cubit.moveJobStatus(jobId: '1', newStatus: 'interviewing');
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.textContaining('Erro ao mover vaga: Exception: Falha de escrita no Postgrest'),
        findsOneWidget,
      );
    });

    testWidgets('supports horizontal scrolling across all 5 columns on narrow viewports',
        (tester) async {
      when(() => mockRepository.getJobs())
          .thenAnswer((_) async => [testJob1, testJob2, testJob3]);

      await cubit.loadJobs();

      // Configure a mobile viewport (e.g. 400x800)
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Horizontal SingleChildScrollView is present
      final horizontalScroll = find.byWidgetPredicate(
        (w) => w is SingleChildScrollView && w.scrollDirection == Axis.horizontal,
      );
      expect(horizontalScroll, findsOneWidget);

      // Scroll horizontally to the end
      await tester.drag(horizontalScroll, const Offset(-800, 0));
      await tester.pumpAndSettle();

      // The last column "Rejeitada" is now scrolled into view
      expect(find.text('Rejeitada'), findsOneWidget);
    });

    testWidgets(
        'archives job from card action menu and displays confirmation SnackBar',
        (tester) async {
      when(() => mockRepository.getJobs())
          .thenAnswer((_) async => [testJob1]);
      when(() => mockRepository.toggleJobArchived(
            jobId: '1',
            isArchived: true,
          )).thenAnswer((_) async {});

      await cubit.loadJobs();

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Senior Flutter Specialist'), findsOneWidget);

      // Open card action menu
      final menuButton = find.byKey(const ValueKey('job_card_menu_1'));
      expect(menuButton, findsOneWidget);
      await tester.tap(menuButton);
      await tester.pumpAndSettle();

      // Tap 'Arquivar vaga'
      expect(find.text('Arquivar vaga'), findsOneWidget);
      await tester.tap(find.text('Arquivar vaga'));
      await tester.pumpAndSettle();

      // Card is removed from Kanban view
      expect(find.text('Senior Flutter Specialist'), findsNothing);

      // Confirmation SnackBar is displayed
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Vaga arquivada com sucesso.'), findsOneWidget);

      verify(() => mockRepository.toggleJobArchived(
            jobId: '1',
            isArchived: true,
          )).called(1);
    });

    testWidgets(
        'moves job status from card action menu and updates funnel',
        (tester) async {
      when(() => mockRepository.getJobs())
          .thenAnswer((_) async => [testJob1]);
      when(() => mockRepository.updateJobStatus(
            jobId: '1',
            newStatus: 'interviewing',
          )).thenAnswer((_) async {});

      await cubit.loadJobs();

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Open menu on job in 'Nova' column
      final menuButton = find.byKey(const ValueKey('job_card_menu_1'));
      await tester.tap(menuButton);
      await tester.pumpAndSettle();

      // Tap 'Mover para Entrevista'
      await tester.tap(find.text('Mover para Entrevista'));
      await tester.pumpAndSettle();

      verify(() => mockRepository.updateJobStatus(
            jobId: '1',
            newStatus: 'interviewing',
          )).called(1);
    });

    testWidgets(
        'moves job status when card is dragged and dropped to another column',
        (tester) async {
      when(() => mockRepository.getJobs())
          .thenAnswer((_) async => [testJob1]);
      when(() => mockRepository.updateJobStatus(
            jobId: '1',
            newStatus: 'interviewing',
          )).thenAnswer((_) async {});

      await cubit.loadJobs();

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      final cardFinder = find.text('Senior Flutter Specialist');
      expect(cardFinder, findsOneWidget);

      final interviewColFinder =
          find.byKey(const ValueKey('kanban_col_interviewing'));
      expect(interviewColFinder, findsOneWidget);

      // Start drag gesture
      final gesture = await tester.startGesture(tester.getCenter(cardFinder));
      await tester.pump(const Duration(milliseconds: 300)); // Activate long press drag

      // Move over to the interview column
      await gesture.moveTo(tester.getCenter(interviewColFinder));
      await tester.pump();

      // Release drop
      await gesture.up();
      await tester.pumpAndSettle();

      verify(() => mockRepository.updateJobStatus(
            jobId: '1',
            newStatus: 'interviewing',
          )).called(1);
    });

    testWidgets('opens JobDetailsModal when a card is tapped and saves notes',
        (tester) async {
      when(() => mockRepository.getJobs())
          .thenAnswer((_) async => [testJob1]);
      when(() => mockRepository.updateJobNotes(
            jobId: '1',
            notes: 'Nova anotação sobre a vaga',
          )).thenAnswer((_) async {});

      await cubit.loadJobs();

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Tap on card
      await tester.tap(find.text('Senior Flutter Specialist'));
      await tester.pumpAndSettle();

      // Modal is visible
      expect(find.byType(JobDetailsModal), findsOneWidget);
      expect(find.text('Notas Pessoais'), findsOneWidget);

      // Edit notes and save
      final notesField = find.byKey(const ValueKey('job_details_notes_field'));
      await tester.enterText(notesField, 'Nova anotação sobre a vaga');
      await tester.pumpAndSettle();

      final saveButton = find.byKey(const ValueKey('job_details_save_notes_button'));
      await tester.ensureVisible(saveButton);
      await tester.pumpAndSettle();
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Modal closed, SnackBar shown
      expect(find.byType(JobDetailsModal), findsNothing);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Anotações salvas com sucesso.'), findsOneWidget);

      verify(() => mockRepository.updateJobNotes(
            jobId: '1',
            notes: 'Nova anotação sobre a vaga',
          )).called(1);
    });

    testWidgets('debounces search input by ~400ms before applying filter',
        (tester) async {
      when(() => mockRepository.getJobs())
          .thenAnswer((_) async => [testJob1, testJob2]);

      await cubit.loadJobs();
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);

      // Digita no campo de busca
      await tester.enterText(searchField, 'Lead Mobile');

      // Antes de 400ms (ex: 200ms), o debounce ainda não expirou
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Senior Flutter Specialist'), findsOneWidget);
      expect(find.text('Lead Mobile Developer'), findsOneWidget);

      // Avança mais 250ms (totalizando > 400ms): debounce dispara
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();

      expect(find.text('Lead Mobile Developer'), findsOneWidget);
      expect(find.text('Senior Flutter Specialist'), findsNothing);
    });

    testWidgets(
        'filters jobs when modality chips are tapped and updates job counter',
        (tester) async {
      when(() => mockRepository.getJobs()).thenAnswer((_) async =>
          [testJobRemote, testJobHybrid, testJobOnSite]);

      await cubit.loadJobs();
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('3 vagas'), findsOneWidget);

      // Toque no chip "Remoto"
      final remoteChip = find.byKey(const ValueKey('chip_modality_remote'));
      expect(remoteChip, findsOneWidget);
      await tester.tap(remoteChip);
      await tester.pumpAndSettle();

      expect(find.text('1 vagas'), findsOneWidget);
      expect(find.text('Flutter Developer Remote'), findsOneWidget);
      expect(find.text('Mobile Engineer Hybrid'), findsNothing);
      expect(find.text('Software Engineer OnSite'), findsNothing);

      // Toque no chip "Híbrido"
      final hybridChip = find.byKey(const ValueKey('chip_modality_hybrid'));
      expect(hybridChip, findsOneWidget);
      await tester.tap(hybridChip);
      await tester.pumpAndSettle();

      expect(find.text('1 vagas'), findsOneWidget);
      expect(find.text('Mobile Engineer Hybrid'), findsOneWidget);
      expect(find.text('Flutter Developer Remote'), findsNothing);

      // Toque no chip "Presencial"
      final onSiteChip = find.byKey(const ValueKey('chip_modality_onSite'));
      expect(onSiteChip, findsOneWidget);
      await tester.tap(onSiteChip);
      await tester.pumpAndSettle();

      expect(find.text('1 vagas'), findsOneWidget);
      expect(find.text('Software Engineer OnSite'), findsOneWidget);
      expect(find.text('Mobile Engineer Hybrid'), findsNothing);

      // Toque no chip "Todos"
      final allChip = find.byKey(const ValueKey('chip_modality_all'));
      expect(allChip, findsOneWidget);
      await tester.tap(allChip);
      await tester.pumpAndSettle();

      expect(find.text('3 vagas'), findsOneWidget);
      expect(find.text('Flutter Developer Remote'), findsOneWidget);
      expect(find.text('Mobile Engineer Hybrid'), findsOneWidget);
      expect(find.text('Software Engineer OnSite'), findsOneWidget);
    });

    testWidgets(
        'renders contextual empty state when search or filter yields no results and resets filters',
        (tester) async {
      when(() => mockRepository.getJobs()).thenAnswer((_) async =>
          [testJobRemote, testJobHybrid, testJobOnSite]);

      await cubit.loadJobs();
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);

      // Busca sem correspondência
      await tester.enterText(searchField, 'Inexistente XYZ');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // KanbanColumn deve ser substituído pelo Empty State
      expect(find.byType(KanbanColumn), findsNothing);
      expect(find.text('Nenhuma vaga encontrada'), findsOneWidget);
      expect(
          find.text(
              'Nenhum resultado corresponde à sua pesquisa ou filtro atual.'),
          findsOneWidget);
      expect(find.text('0 vagas'), findsOneWidget);

      final resetButton = find.byKey(const Key('reset_filters_button'));
      expect(resetButton, findsOneWidget);

      // Tocar no botão "Redefinir filtros"
      await tester.tap(resetButton);
      await tester.pumpAndSettle();

      // Todas as 3 vagas e as 5 colunas restauradas
      expect(find.byType(KanbanColumn), findsNWidgets(5));
      expect(find.text('3 vagas'), findsOneWidget);
      expect(find.text('Flutter Developer Remote'), findsOneWidget);
      expect(find.text('Mobile Engineer Hybrid'), findsOneWidget);
      expect(find.text('Software Engineer OnSite'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      final textWidget = tester.widget<TextField>(searchField);
      expect(textWidget.controller?.text, isEmpty);
    });

    testWidgets(
        'empty filtered state adapts without overflow on reduced vertical viewport',
        (tester) async {
      when(() => mockRepository.getJobs())
          .thenAnswer((_) async => [testJobRemote]);

      await cubit.loadJobs();

      // Viewport vertical reduzido simulando teclado aberto em tela móvel
      tester.view.physicalSize = const Size(400, 340);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'SemResultado');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.text('Nenhuma vaga encontrada'), findsOneWidget);
      expect(find.byKey(const Key('reset_filters_button')), findsOneWidget);

      // Garante que o scroll vertical funciona sem erros de overflow de pixels
      final emptyScroll = find.byWidgetPredicate(
        (w) => w is SingleChildScrollView && w.scrollDirection == Axis.vertical,
      );
      expect(emptyScroll, findsOneWidget);
      await tester.drag(emptyScroll, const Offset(0, -100));
      await tester.pumpAndSettle();
    });

    testWidgets(
        'unfocuses search text field when tapping outside on the background',
        (tester) async {
      when(() => mockRepository.getJobs())
          .thenAnswer((_) async => [testJob1, testJob2]);

      await cubit.loadJobs();
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);

      // Foca no campo de busca
      await tester.tap(searchField);
      await tester.pumpAndSettle();

      final FocusNode firstFocus = FocusScope.of(tester.element(searchField));
      expect(firstFocus.hasFocus, isTrue);

      // Toca no fundo/fora do campo de busca
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      expect(firstFocus.hasFocus, isFalse);
    });

    testWidgets(
        'navigates to ArchivedJobsScreen and re-synchronizes jobs on return',
        (tester) async {
      when(() => mockRepository.getJobs())
          .thenAnswer((_) async => [testJob1]);
      when(() => mockRepository.getArchivedJobs())
          .thenAnswer((_) async => []);

      await cubit.loadJobs();
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      final archiveButton = find.byTooltip('Vagas arquivadas');
      expect(archiveButton, findsOneWidget);

      await tester.tap(archiveButton);
      await tester.pumpAndSettle();

      expect(find.byType(ArchivedJobsScreen), findsOneWidget);

      // Volta para a tela principal
      await tester.tap(find.byTooltip('Voltar'));
      await tester.pumpAndSettle();

      expect(find.byType(ArchivedJobsScreen), findsNothing);
      expect(find.byType(JobsKanbanPage), findsOneWidget);
      // Sincronizou chamando getJobs novamente
      verify(() => mockRepository.getJobs()).called(2);
    });

    testWidgets(
        'navigates to AnalyticsDashboardScreen and re-synchronizes jobs on return',
        (tester) async {
      when(() => mockRepository.getJobs())
          .thenAnswer((_) async => [testJob1]);
      when(() => mockRepository.getJobs(limit: any(named: 'limit')))
          .thenAnswer((_) async => [testJob1]);

      await cubit.loadJobs();
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      final dashboardButton = find.byTooltip('Dashboard e Métricas');
      expect(dashboardButton, findsOneWidget);

      await tester.tap(dashboardButton);
      await tester.pumpAndSettle();

      expect(find.byType(AnalyticsDashboardScreen), findsOneWidget);

      // Volta para a tela principal
      await tester.tap(find.byTooltip('Voltar'));
      await tester.pumpAndSettle();

      expect(find.byType(AnalyticsDashboardScreen), findsNothing);
      expect(find.byType(JobsKanbanPage), findsOneWidget);
      // Sincronizou chamando getJobs novamente
      verify(() => mockRepository.getJobs()).called(2);
    });

    testWidgets('navigates to SearchConfigsScreen from AppBar', (tester) async {
      final mockSearchConfigsRepository = MockSearchConfigsRepository();
      when(() => mockSearchConfigsRepository.getConfigs())
          .thenAnswer((_) async => []);

      when(() => mockRepository.getJobs())
          .thenAnswer((_) async => [testJob1]);
      when(() => mockRepository.getJobs(limit: any(named: 'limit')))
          .thenAnswer((_) async => [testJob1]);

      await cubit.loadJobs();
      await tester.pumpWidget(buildSubject(
        searchConfigsRepository: mockSearchConfigsRepository,
      ));
      await tester.pumpAndSettle();

      final searchConfigsButton = find.byTooltip('Configurações de busca');
      expect(searchConfigsButton, findsOneWidget);

      await tester.tap(searchConfigsButton);
      await tester.pumpAndSettle();

      expect(find.byType(SearchConfigsScreen), findsOneWidget);

      // Volta para a tela principal
      await tester.tap(find.byTooltip('Voltar'));
      await tester.pumpAndSettle();

      expect(find.byType(SearchConfigsScreen), findsNothing);
      expect(find.byType(JobsKanbanPage), findsOneWidget);
    });
  });
}
