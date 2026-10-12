import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:job_hunter_app/core/errors/job_failure.dart';
import 'package:job_hunter_app/core/theme/app_theme.dart';
import 'package:job_hunter_app/core/theme/app_typography.dart';
import 'package:job_hunter_app/features/jobs/domain/models/job_item.dart';
import 'package:job_hunter_app/features/jobs/domain/models/job_status.dart';
import 'package:job_hunter_app/features/jobs/domain/repositories/job_repository.dart';
import 'package:job_hunter_app/features/jobs/presentation/cubit/archived_jobs_cubit.dart';
import 'package:job_hunter_app/features/jobs/presentation/pages/archived_jobs_screen.dart';
import 'package:job_hunter_app/features/jobs/presentation/widgets/job_details_modal.dart';
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
  late ArchivedJobsCubit cubit;

  final testJob1 = JobItem(
    jobId: 'archived-1',
    title: 'Senior Flutter Specialist',
    companyName: 'Apex Tech',
    platform: 'LinkedIn',
    jobUrl: 'https://example.com/1',
    status: JobStatus.rejected,
    location: 'Remoto',
    salaryText: 'R\$ 15.000',
    isArchived: true,
  );

  final testJob2 = JobItem(
    jobId: 'archived-2',
    title: 'Backend Node.js Dev',
    companyName: 'Metro Inc',
    platform: 'Gupy',
    jobUrl: 'https://example.com/2',
    status: JobStatus.newJob,
    isArchived: true,
  );

  setUp(() {
    mockRepository = MockJobRepository();
    cubit = ArchivedJobsCubit(mockRepository);
  });

  tearDown(() {
    cubit.close();
  });

  Widget buildSubject({ArchivedJobsCubit? customCubit}) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: ArchivedJobsScreen(cubit: customCubit ?? cubit),
    );
  }

  group('ArchivedJobsScreen', () {
    testWidgets('renders CircularProgressIndicator while loading', (tester) async {
      final completer = Completer<List<JobItem>>();
      when(() => mockRepository.getArchivedJobs())
          .thenAnswer((_) => completer.future);

      cubit.loadArchivedJobs();

      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Vagas Arquivadas'), findsOneWidget);
    });

    testWidgets('renders empty state when there are no archived jobs', (tester) async {
      when(() => mockRepository.getArchivedJobs())
          .thenAnswer((_) async => <JobItem>[]);

      await cubit.loadArchivedJobs();

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Nenhuma vaga arquivada'), findsOneWidget);
      expect(
        find.text(
          'Vagas descartadas no quadro aparecerão aqui para auditoria e recuperação.',
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
    });

    testWidgets('renders error view with retry button on failure and retries on tap', (tester) async {
      when(() => mockRepository.getArchivedJobs())
          .thenThrow(const JobFetchFailure('Falha ao conectar ao Supabase'));

      await cubit.loadArchivedJobs();

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Falha ao conectar ao Supabase'),
        findsOneWidget,
      );
      expect(find.text('Tentar novamente'), findsOneWidget);

      when(() => mockRepository.getArchivedJobs())
          .thenAnswer((_) async => [testJob1]);

      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();

      expect(find.text('Senior Flutter Specialist'), findsOneWidget);
    });

    testWidgets('renders list of archived jobs with details, badges, and restore button', (tester) async {
      when(() => mockRepository.getArchivedJobs())
          .thenAnswer((_) async => [testJob1, testJob2]);

      await cubit.loadArchivedJobs();

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Senior Flutter Specialist'), findsOneWidget);
      expect(find.text('Apex Tech'), findsOneWidget);
      expect(find.text('Backend Node.js Dev'), findsOneWidget);
      expect(find.text('Metro Inc'), findsOneWidget);
      expect(find.text('Restaurar'), findsNWidgets(2));
      expect(find.text('Remoto'), findsOneWidget);
      expect(find.text('R\$ 15.000'), findsOneWidget);
    });

    testWidgets('tapping restore button calls restoreJob and displays success snackbar', (tester) async {
      when(() => mockRepository.getArchivedJobs())
          .thenAnswer((_) async => [testJob1]);
      when(() => mockRepository.toggleJobArchived(
            jobId: 'archived-1',
            isArchived: false,
          )).thenAnswer((_) async {});

      await cubit.loadArchivedJobs();

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Senior Flutter Specialist'), findsOneWidget);

      await tester.tap(find.text('Restaurar'));
      await tester.pumpAndSettle();

      verify(() => mockRepository.toggleJobArchived(
            jobId: 'archived-1',
            isArchived: false,
          )).called(1);

      expect(find.text('Vaga restaurada com sucesso.'), findsOneWidget);
      expect(find.text('Nenhuma vaga arquivada'), findsOneWidget);
    });

    testWidgets('displays error snackbar when restoreJob fails', (tester) async {
      when(() => mockRepository.getArchivedJobs())
          .thenAnswer((_) async => [testJob1]);
      when(() => mockRepository.toggleJobArchived(
            jobId: 'archived-1',
            isArchived: false,
          )).thenThrow(const JobMutationFailure('Erro de conexão ao restaurar'));

      await cubit.loadArchivedJobs();

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Restaurar'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.textContaining('Erro de conexão ao restaurar'),
        findsOneWidget,
      );
      // Item remains in the list after rollback
      expect(find.text('Senior Flutter Specialist'), findsOneWidget);
    });

    testWidgets('tapping job card opens JobDetailsModal', (tester) async {
      when(() => mockRepository.getArchivedJobs())
          .thenAnswer((_) async => [testJob1]);

      await cubit.loadArchivedJobs();

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Senior Flutter Specialist'));
      await tester.pumpAndSettle();

      expect(find.byType(JobDetailsModal), findsOneWidget);
    });

    testWidgets('tapping refresh button in AppBar calls loadArchivedJobs', (tester) async {
      when(() => mockRepository.getArchivedJobs())
          .thenAnswer((_) async => [testJob1]);

      await cubit.loadArchivedJobs();

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Atualizar vagas arquivadas'));
      await tester.pumpAndSettle();

      verify(() => mockRepository.getArchivedJobs()).called(2);
    });

    testWidgets('tapping back button in AppBar pops the route', (tester) async {
      when(() => mockRepository.getArchivedJobs())
          .thenAnswer((_) async => [testJob1]);

      await cubit.loadArchivedJobs();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).push(
                    MaterialPageRoute(
                      builder: (_) => ArchivedJobsScreen(cubit: cubit),
                    ),
                  );
                },
                child: const Text('Go to archived'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Go to archived'));
      await tester.pumpAndSettle();

      expect(find.byType(ArchivedJobsScreen), findsOneWidget);

      await tester.tap(find.byTooltip('Voltar'));
      await tester.pumpAndSettle();

      expect(find.byType(ArchivedJobsScreen), findsNothing);
      expect(find.text('Go to archived'), findsOneWidget);
    });
  });
}
