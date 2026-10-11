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
import 'package:job_hunter_app/features/jobs/presentation/pages/jobs_kanban_page.dart';
import 'package:job_hunter_app/features/jobs/presentation/widgets/kanban_column.dart';
import 'package:job_hunter_app/features/jobs/presentation/widgets/kanban_error_view.dart';
import 'package:job_hunter_app/features/jobs/presentation/widgets/kanban_loading_skeleton.dart';
import 'package:mocktail/mocktail.dart';

class MockJobsRepository extends Mock implements JobsRepository {}

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

  setUp(() {
    mockRepository = MockJobsRepository();
    cubit = JobsCubit(mockRepository);
  });

  tearDown(() {
    cubit.close();
  });

  Widget buildSubject({JobsCubit? customCubit}) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: JobsKanbanPage(cubit: customCubit ?? cubit),
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
            newStatus: 'interview',
          )).thenThrow(Exception('Falha de escrita no Postgrest'));

      await cubit.loadJobs();

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Trigger move that will fail and rollback
      await cubit.moveJobStatus(jobId: '1', newStatus: 'interview');
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
  });
}
