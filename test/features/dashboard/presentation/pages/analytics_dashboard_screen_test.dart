import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:job_hunter_app/core/theme/app_theme.dart';
import 'package:job_hunter_app/core/theme/app_typography.dart';
import 'package:job_hunter_app/features/dashboard/presentation/cubit/analytics_dashboard_cubit.dart';
import 'package:job_hunter_app/features/dashboard/presentation/pages/analytics_dashboard_screen.dart';
import 'package:job_hunter_app/features/dashboard/presentation/widgets/analytics_empty_view.dart';
import 'package:job_hunter_app/features/dashboard/presentation/widgets/analytics_error_view.dart';
import 'package:job_hunter_app/features/dashboard/presentation/widgets/analytics_loading_view.dart';
import 'package:job_hunter_app/features/dashboard/presentation/widgets/metric_kpi_card.dart';
import 'package:job_hunter_app/features/dashboard/presentation/widgets/status_distribution_card.dart';
import 'package:job_hunter_app/features/jobs/domain/models/job_item.dart';
import 'package:job_hunter_app/features/jobs/domain/models/job_status.dart';
import 'package:job_hunter_app/features/jobs/domain/repositories/job_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockJobRepository extends Mock implements IJobRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    AppTypography.useSystemFonts = true;
  });

  tearDownAll(() {
    AppTypography.useSystemFonts = false;
  });

  late MockJobRepository mockRepository;
  late AnalyticsDashboardCubit cubit;

  final testJob1 = JobItem(
    jobId: '1',
    title: 'Senior Flutter Specialist',
    companyName: 'Apex Tech',
    platform: 'LinkedIn',
    jobUrl: 'https://example.com/1',
    status: JobStatus.newJob,
  );

  final testJob2 = JobItem(
    jobId: '2',
    title: 'Lead Mobile Developer',
    companyName: 'Apex Tech',
    platform: 'Gupy',
    jobUrl: 'https://example.com/2',
    status: JobStatus.applied,
  );

  final testJob3 = JobItem(
    jobId: '3',
    title: 'Tech Lead',
    companyName: 'Beta Inc',
    platform: 'Catho',
    jobUrl: 'https://example.com/3',
    status: JobStatus.interview,
  );

  final testJob4 = JobItem(
    jobId: '4',
    title: 'Staff Engineer',
    companyName: 'Gamma Corp',
    platform: 'LinkedIn',
    jobUrl: 'https://example.com/4',
    status: JobStatus.offer,
  );

  final testJob5 = JobItem(
    jobId: '5',
    title: 'Discarded Dev',
    companyName: 'Delta Corp',
    platform: 'LinkedIn',
    jobUrl: 'https://example.com/5',
    status: JobStatus.rejected,
  );

  final testArchivedJob = JobItem(
    jobId: '6',
    title: 'Old Job',
    companyName: 'Old Inc',
    platform: 'LinkedIn',
    jobUrl: 'https://example.com/6',
    status: JobStatus.applied,
    isArchived: true,
  );

  setUp(() {
    mockRepository = MockJobRepository();
    cubit = AnalyticsDashboardCubit(mockRepository);
  });

  tearDown(() {
    cubit.close();
  });

  Widget buildSubject({AnalyticsDashboardCubit? customCubit}) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: AnalyticsDashboardScreen(
        cubit: customCubit ?? cubit,
      ),
    );
  }

  group('AnalyticsDashboardScreen', () {
    testWidgets('renders AnalyticsLoadingView when state is loading',
        (tester) async {
      final completer = Completer<List<JobItem>>();
      when(() => mockRepository.getJobs(limit: any(named: 'limit')))
          .thenAnswer((_) => completer.future);

      unawaited(cubit.loadMetrics());

      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.byType(AnalyticsLoadingView), findsOneWidget);
      expect(find.text('Carregando métricas do funil...'), findsOneWidget);

      completer.complete([]);
      await tester.pumpAndSettle();
    });

    testWidgets('renders AnalyticsEmptyView when no jobs exist',
        (tester) async {
      when(() => mockRepository.getJobs(limit: any(named: 'limit')))
          .thenAnswer((_) async => []);

      await cubit.loadMetrics();

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byType(AnalyticsEmptyView), findsOneWidget);
      expect(find.text('Nenhuma vaga no funil'), findsOneWidget);
      expect(find.text('Atualizar métricas'), findsOneWidget);

      // Tapping refresh on empty view re-triggers loadMetrics
      await tester.tap(find.text('Atualizar métricas'));
      verify(() => mockRepository.getJobs(limit: 500)).called(2);
    });

    testWidgets('renders AnalyticsErrorView and allows retry when repository fails',
        (tester) async {
      when(() => mockRepository.getJobs(limit: any(named: 'limit')))
          .thenThrow(Exception('Timeout de conexão'));

      await cubit.loadMetrics();

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byType(AnalyticsErrorView), findsOneWidget);
      expect(find.text('Falha ao carregar métricas'), findsOneWidget);
      expect(find.textContaining('Timeout de conexão'), findsOneWidget);

      when(() => mockRepository.getJobs(limit: any(named: 'limit')))
          .thenAnswer((_) async => [testJob1]);

      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();

      expect(find.byType(AnalyticsErrorView), findsNothing);
      expect(find.byType(MetricKpiCard), findsWidgets);
    });

    testWidgets('renders all 4 KPI cards and StatusDistributionCard when loaded',
        (tester) async {
      final testJobs = [
        testJob1, // new
        testJob2, // applied
        testJob3, // interview
        testJob4, // offer
        testJob5, // rejected
        testArchivedJob, // archived
      ];

      when(() => mockRepository.getJobs(limit: any(named: 'limit')))
          .thenAnswer((_) async => testJobs);

      await cubit.loadMetrics();

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Check header and tags
      expect(find.text('DASHBOARD'), findsOneWidget);
      expect(find.text('Dashboard e Métricas'), findsOneWidget);

      // Check KPI Cards
      expect(find.text('Total Ativo no Funil'), findsOneWidget);
      expect(find.text('Candidaturas Submetidas'), findsOneWidget);
      expect(find.text('Taxa de Conversão'), findsOneWidget);
      expect(find.text('Ofertas Recebidas'), findsOneWidget);

      // Values:
      // Active in funnel (!archived & != rejected): 4 (new, applied, interview, offer)
      expect(find.text('4'), findsWidgets);
      // Submetidas (applied, interview, offer): 3
      expect(find.text('3'), findsWidgets);
      // Conversão: (1 interview + 1 offer) / 3 * 100 = 66.7%
      expect(find.text('66.7%'), findsOneWidget);
      // Ofertas: 1
      expect(find.text('1'), findsWidgets);

      // StatusDistributionCard
      expect(find.byType(StatusDistributionCard), findsOneWidget);
      expect(find.text('Distribuição por Status'), findsOneWidget);
      expect(find.text('Novas Vagas'), findsOneWidget);
      expect(find.text('Candidatadas'), findsOneWidget);
      expect(find.text('Em Entrevista'), findsOneWidget);
      expect(find.text('Ofertas / Propostas'), findsOneWidget);
      expect(find.text('Rejeitadas'), findsOneWidget);

      // History Summary Card
      expect(find.text('Histórico Geral e Auditoria'), findsOneWidget);
      expect(find.textContaining('Total de registros: 6'), findsOneWidget);
      expect(find.textContaining('Vagas arquivadas: 1'), findsOneWidget);
    });

    testWidgets('tapping back button in AppBar pops the route',
        (tester) async {
      when(() => mockRepository.getJobs(limit: any(named: 'limit')))
          .thenAnswer((_) async => [testJob1]);

      await cubit.loadMetrics();

      bool didPop = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Navigator(
            onDidRemovePage: (page) => didPop = true,
            pages: [
              MaterialPage(
                child: AnalyticsDashboardScreen(cubit: cubit),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      final backButton = find.byTooltip('Voltar');
      expect(backButton, findsOneWidget);

      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(didPop, isTrue);
    });

    testWidgets('tapping refresh in AppBar re-queries repository',
        (tester) async {
      when(() => mockRepository.getJobs(limit: any(named: 'limit')))
          .thenAnswer((_) async => [testJob1]);

      await cubit.loadMetrics();

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      final refreshButton = find.byTooltip('Atualizar métricas');
      expect(refreshButton, findsOneWidget);

      await tester.tap(refreshButton);
      await tester.pumpAndSettle();

      verify(() => mockRepository.getJobs(limit: 500)).called(2);
    });

    testWidgets('adapts responsively on tablet viewport without overflow errors',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      when(() => mockRepository.getJobs(limit: any(named: 'limit')))
          .thenAnswer((_) async => [testJob1, testJob2, testJob3]);

      await cubit.loadMetrics();

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byType(MetricKpiCard), findsNWidgets(4));
      expect(find.byType(StatusDistributionCard), findsOneWidget);
    });
  });
}
