import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:job_hunter_app/core/constants/app_constants.dart';
import 'package:job_hunter_app/core/theme/app_typography.dart';
import 'package:job_hunter_app/features/jobs/domain/models/job_item.dart';
import 'package:job_hunter_app/features/jobs/domain/repositories/job_repository.dart';
import 'package:job_hunter_app/features/jobs/presentation/pages/jobs_kanban_page.dart';
import 'package:job_hunter_app/main.dart';

class MockJobsRepository extends Mock implements IJobRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockJobsRepository mockJobsRepository;

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    AppTypography.useSystemFonts = true;
  });

  setUp(() {
    mockJobsRepository = MockJobsRepository();
    when(() => mockJobsRepository.getJobs(
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
          statusFilter: any(named: 'statusFilter'),
          query: any(named: 'query'),
          userId: any(named: 'userId'),
        )).thenAnswer((_) async => <JobItem>[]);
    when(() => mockJobsRepository.getJobs())
        .thenAnswer((_) async => <JobItem>[]);
  });

  tearDownAll(() {
    AppTypography.useSystemFonts = false;
  });

  testWidgets('JobHunterApp renders JobsKanbanScreen as definitive home screen',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      JobHunterApp(jobsRepository: mockJobsRepository),
    );
    await tester.pumpAndSettle();

    // Verify Kanban title and tag badge
    expect(find.byType(JobsKanbanScreen), findsOneWidget);
    expect(find.text('Quadro de Vagas'), findsOneWidget);
    expect(find.text('KANBAN'), findsOneWidget);

    // Verify mandatory quick access actions in AppBar
    expect(find.byIcon(Icons.insights_outlined), findsOneWidget);
    expect(find.byTooltip('Dashboard e Métricas'), findsOneWidget);

    expect(find.byIcon(Icons.tune_outlined), findsOneWidget);
    expect(find.byTooltip('Configurações de busca'), findsOneWidget);

    expect(find.byIcon(Icons.archive_outlined), findsOneWidget);
    expect(find.byTooltip('Vagas arquivadas'), findsOneWidget);
  });

  testWidgets(
      'JobHunterApp displays diagnostic warning when bootstrap error occurs',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const JobHunterApp(
        bootstrapError: 'Variável SUPABASE_URL não configurada no .env',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('CONFIG REQUIRED'), findsOneWidget);
    expect(
        find.text('Atenção: Configuração de Ambiente Pendente'), findsOneWidget);
    expect(
      find.text('Variável SUPABASE_URL não configurada no .env'),
      findsOneWidget,
    );
  });

  testWidgets(
      'BootstrapHomeScreen showcase renders correctly when explicitly provided',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const JobHunterApp(home: BootstrapHomeScreen()),
    );
    await tester.pumpAndSettle();

    // Verify app title and terminal badge
    expect(find.text(AppConstants.appName), findsOneWidget);
    expect(find.text('JH-CORE'), findsOneWidget);
    expect(find.text('ONLINE'), findsOneWidget);

    // Verify foundational modules card
    expect(find.text('Spec 001: Bootstrap & Arquitetura Frontend'),
        findsOneWidget);
    expect(find.text('core/theme'), findsOneWidget);
    expect(find.text('core/services'), findsOneWidget);
    expect(find.text('features/jobs'), findsOneWidget);

    // Verify Kanban status chips
    expect(find.textContaining('Nova (new)'), findsOneWidget);
    expect(find.textContaining('Candidatado (applied)'), findsOneWidget);
    expect(find.textContaining('Entrevista (interviewing)'), findsOneWidget);
    expect(find.textContaining('Proposta (offer)'), findsOneWidget);
    expect(find.textContaining('Rejeitada (rejected)'), findsOneWidget);
  });
}
