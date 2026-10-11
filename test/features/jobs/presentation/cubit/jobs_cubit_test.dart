import 'package:flutter_test/flutter_test.dart';
import 'package:job_hunter_app/features/jobs/domain/models/job_item.dart';
import 'package:job_hunter_app/features/jobs/domain/models/job_modality.dart';
import 'package:job_hunter_app/features/jobs/domain/models/job_status.dart';
import 'package:job_hunter_app/features/jobs/domain/models/user_job_interaction.dart';
import 'package:job_hunter_app/features/jobs/domain/repositories/jobs_repository.dart';
import 'package:job_hunter_app/features/jobs/presentation/cubit/jobs_cubit.dart';
import 'package:job_hunter_app/features/jobs/presentation/cubit/jobs_state.dart';
import 'package:mocktail/mocktail.dart';

class MockJobsRepository extends Mock implements JobsRepository {}

void main() {
  late MockJobsRepository mockRepository;
  late JobsCubit cubit;

  final testJob1 = JobItem(
    jobId: '1',
    title: 'Senior Flutter Developer',
    companyName: 'Tech Innovations',
    platform: 'LinkedIn',
    jobUrl: 'https://example.com/job/1',
    status: JobStatus.newJob,
    location: 'Remoto',
    createdAt: DateTime.now(),
  );

  final testJob2 = JobItem(
    jobId: '2',
    title: 'Mobile Engineer',
    companyName: 'AppStudio',
    platform: 'Gupy',
    jobUrl: 'https://example.com/job/2',
    status: JobStatus.applied,
    location: 'São Paulo, SP (Híbrido)',
    createdAt: DateTime.now(),
  );

  final testArchivedJob = JobItem(
    jobId: '3',
    title: 'Backend Python',
    companyName: 'OldCorp',
    platform: 'Catho',
    jobUrl: 'https://example.com/job/3',
    status: JobStatus.rejected,
    isArchived: true,
    createdAt: DateTime.now(),
  );

  final testJobOnSite = JobItem(
    jobId: '4',
    title: 'Engenheiro de Software',
    companyName: 'Banco Seguro',
    platform: 'Gupy',
    jobUrl: 'https://example.com/job/4',
    status: JobStatus.newJob,
    location: 'Belo Horizonte, MG (Presencial)',
    createdAt: DateTime.now(),
  );

  setUp(() {
    mockRepository = MockJobsRepository();
    cubit = JobsCubit(mockRepository);
  });

  tearDown(() {
    cubit.close();
  });

  group('JobsCubit', () {
    test('initial state is JobsInitial', () {
      expect(cubit.state, const JobsInitial());
    });

    test('emits [JobsLoading, JobsLoaded] when loadJobs succeeds and omits archived', () async {
      when(() => mockRepository.getJobs()).thenAnswer(
        (_) async => [testJob1, testJob2, testArchivedJob],
      );

      final expectedStates = [
        const JobsLoading(),
        JobsLoaded([testJob1, testJob2]),
      ];

      expectLater(cubit.stream, emitsInOrder(expectedStates));

      await cubit.loadJobs();
      expect(cubit.state, isA<JobsLoaded>());
      final loaded = cubit.state as JobsLoaded;
      expect(loaded.jobs.length, 2);
      expect(loaded.jobsByStatus(JobStatus.newJob).length, 1);
      expect(loaded.jobsByStatus(JobStatus.applied).length, 1);
    });

    test('emits [JobsLoading, JobsError] when loadJobs fails', () async {
      when(() => mockRepository.getJobs()).thenThrow(Exception('Network error'));

      final expectedStates = [
        const JobsLoading(),
        isA<JobsError>(),
      ];

      expectLater(cubit.stream, emitsInOrder(expectedStates));

      await cubit.loadJobs();
    });

    test('optimistically updates job status and calls repository', () async {
      when(() => mockRepository.getJobs()).thenAnswer((_) async => [testJob1]);
      when(() => mockRepository.updateJobStatus(
            jobId: '1',
            newStatus: 'interview',
          )).thenAnswer((_) async {});

      await cubit.loadJobs();

      final updatedJob = testJob1.copyWith(status: JobStatus.interview);

      expectLater(
        cubit.stream,
        emits(JobsLoaded([updatedJob])),
      );

      await cubit.moveJobStatus(jobId: '1', newStatus: 'interview');

      verify(() => mockRepository.updateJobStatus(
            jobId: '1',
            newStatus: 'interview',
          )).called(1);
    });

    test('rolls back to previous state when moveJobStatus fails', () async {
      when(() => mockRepository.getJobs()).thenAnswer((_) async => [testJob1]);
      when(() => mockRepository.updateJobStatus(
            jobId: '1',
            newStatus: 'interview',
          )).thenThrow(Exception('Falha no banco Supabase'));

      await cubit.loadJobs();

      final optimisticJob = testJob1.copyWith(status: JobStatus.interview);

      expectLater(
        cubit.stream,
        emitsInOrder([
          JobsLoaded([optimisticJob]),
          JobsLoaded([testJob1], errorMessage: 'Erro ao mover vaga: Exception: Falha no banco Supabase'),
        ]),
      );

      await cubit.moveJobStatus(jobId: '1', newStatus: 'interview');

      verify(() => mockRepository.updateJobStatus(
            jobId: '1',
            newStatus: 'interview',
          )).called(1);
    });

    test('optimistically removes job and emits successMessage when archiveJob succeeds', () async {
      when(() => mockRepository.getJobs()).thenAnswer((_) async => [testJob1, testJob2]);
      when(() => mockRepository.toggleJobArchived(
            jobId: '1',
            isArchived: true,
          )).thenAnswer((_) async {});

      await cubit.loadJobs();

      expectLater(
        cubit.stream,
        emitsInOrder([
          JobsLoaded([testJob2]),
          JobsLoaded([testJob2], successMessage: 'Vaga arquivada com sucesso.'),
        ]),
      );

      await cubit.archiveJob('1');

      verify(() => mockRepository.toggleJobArchived(
            jobId: '1',
            isArchived: true,
          )).called(1);
    });

    test('rolls back to previous list when archiveJob fails', () async {
      when(() => mockRepository.getJobs()).thenAnswer((_) async => [testJob1, testJob2]);
      when(() => mockRepository.toggleJobArchived(
            jobId: '1',
            isArchived: true,
          )).thenThrow(Exception('Erro de rede'));

      await cubit.loadJobs();

      expectLater(
        cubit.stream,
        emitsInOrder([
          JobsLoaded([testJob2]),
          JobsLoaded(
            [testJob1, testJob2],
            errorMessage: 'Erro ao arquivar vaga: Exception: Erro de rede',
          ),
        ]),
      );

      await cubit.archiveJob('1');
    });

    test('filters jobs in memory by text query and restores when cleared', () async {
      when(() => mockRepository.getJobs()).thenAnswer((_) async => [testJob1, testJob2]);
      await cubit.loadJobs();

      // Busca por 'Flutter' deve retornar apenas testJob1
      cubit.filterJobs('Flutter');
      var loaded = cubit.state as JobsLoaded;
      expect(loaded.jobs.length, 1);
      expect(loaded.jobs.first.jobId, '1');
      expect(loaded.searchQuery, 'Flutter');

      // Busca por empresa 'AppStudio' deve retornar testJob2
      cubit.filterJobs('AppStudio');
      loaded = cubit.state as JobsLoaded;
      expect(loaded.jobs.length, 1);
      expect(loaded.jobs.first.jobId, '2');

      // Limpar busca deve restaurar ambas as vagas
      cubit.filterJobs('');
      loaded = cubit.state as JobsLoaded;
      expect(loaded.jobs.length, 2);
      expect(loaded.searchQuery, isNull);
    });

    test('filters jobs by modality filter and combines with text search', () async {
      when(() => mockRepository.getJobs())
          .thenAnswer((_) async => [testJob1, testJob2, testJobOnSite]);
      await cubit.loadJobs();

      // Inicialmente 3 vagas
      expect((cubit.state as JobsLoaded).jobs.length, 3);

      // Filtro Remoto -> apenas testJob1
      cubit.setModalityFilter(JobModalityFilter.remote);
      var state = cubit.state as JobsLoaded;
      expect(state.selectedModality, JobModalityFilter.remote);
      expect(state.jobs.length, 1);
      expect(state.jobs.first.jobId, '1');

      // Filtro Híbrido -> apenas testJob2
      cubit.setModalityFilter(JobModalityFilter.hybrid);
      state = cubit.state as JobsLoaded;
      expect(state.selectedModality, JobModalityFilter.hybrid);
      expect(state.jobs.length, 1);
      expect(state.jobs.first.jobId, '2');

      // Filtro Presencial -> apenas testJobOnSite
      cubit.setModalityFilter(JobModalityFilter.onSite);
      state = cubit.state as JobsLoaded;
      expect(state.selectedModality, JobModalityFilter.onSite);
      expect(state.jobs.length, 1);
      expect(state.jobs.first.jobId, '4');

      // Filtro Todos -> restaura 3 vagas
      cubit.setModalityFilter(JobModalityFilter.all);
      state = cubit.state as JobsLoaded;
      expect(state.jobs.length, 3);

      // Combinação: Filtro Remoto + Busca por texto 'Flutter' -> testJob1
      cubit.setModalityFilter(JobModalityFilter.remote);
      cubit.filterJobs('Flutter');
      state = cubit.state as JobsLoaded;
      expect(state.jobs.length, 1);
      expect(state.jobs.first.jobId, '1');
      expect(state.hasActiveFilter, isTrue);

      // Combinação sem correspondência: Remoto + 'Banco' -> 0 vagas
      cubit.filterJobs('Banco');
      state = cubit.state as JobsLoaded;
      expect(state.jobs, isEmpty);
      expect(state.hasActiveFilter, isTrue);

      // Reset completo restaura tudo
      cubit.resetFilters();
      state = cubit.state as JobsLoaded;
      expect(state.jobs.length, 3);
      expect(state.searchQuery, isNull);
      expect(state.selectedModality, JobModalityFilter.all);
      expect(state.hasActiveFilter, isFalse);
    });

    test('clears error message when clearErrorMessage is called', () async {
      when(() => mockRepository.getJobs()).thenAnswer((_) async => [testJob1]);
      when(() => mockRepository.updateJobStatus(
            jobId: '1',
            newStatus: 'rejected',
          )).thenThrow(Exception('Fail'));

      await cubit.loadJobs();
      await cubit.moveJobStatus(jobId: '1', newStatus: 'rejected');

      var state = cubit.state as JobsLoaded;
      expect(state.errorMessage, isNotNull);

      cubit.clearErrorMessage();
      state = cubit.state as JobsLoaded;
      expect(state.errorMessage, isNull);
    });

    test('clears success message when clearSuccessMessage is called', () async {
      when(() => mockRepository.getJobs()).thenAnswer((_) async => [testJob1, testJob2]);
      when(() => mockRepository.toggleJobArchived(
            jobId: '1',
            isArchived: true,
          )).thenAnswer((_) async {});

      await cubit.loadJobs();
      await cubit.archiveJob('1');

      var state = cubit.state as JobsLoaded;
      expect(state.successMessage, 'Vaga arquivada com sucesso.');

      cubit.clearSuccessMessage();
      state = cubit.state as JobsLoaded;
      expect(state.successMessage, isNull);
    });

    test('optimistically updates notes and emits successMessage when updateJobNotes succeeds', () async {
      when(() => mockRepository.getJobs()).thenAnswer((_) async => [testJob1]);
      when(() => mockRepository.updateJobNotes(
            jobId: '1',
            notes: 'Entrevista marcada para terça-feira.',
          )).thenAnswer((_) async {});

      await cubit.loadJobs();
      await cubit.updateJobNotes(
        jobId: '1',
        notes: 'Entrevista marcada para terça-feira.',
      );

      verify(() => mockRepository.updateJobNotes(
            jobId: '1',
            notes: 'Entrevista marcada para terça-feira.',
          )).called(1);

      final state = cubit.state as JobsLoaded;
      expect(state.jobs.first.notes, 'Entrevista marcada para terça-feira.');
      expect(state.successMessage, 'Anotações salvas com sucesso.');
    });

    test('rolls back notes and emits errorMessage when updateJobNotes fails', () async {
      final jobWithInitialNotes = testJob1.copyWith(notes: 'Nota anterior');
      when(() => mockRepository.getJobs()).thenAnswer((_) async => [jobWithInitialNotes]);
      when(() => mockRepository.updateJobNotes(
            jobId: '1',
            notes: 'Nova nota com falha',
          )).thenThrow(Exception('Supabase write failure'));

      await cubit.loadJobs();
      await cubit.updateJobNotes(
        jobId: '1',
        notes: 'Nova nota com falha',
      );

      verify(() => mockRepository.updateJobNotes(
            jobId: '1',
            notes: 'Nova nota com falha',
          )).called(1);

      final state = cubit.state as JobsLoaded;
      expect(state.jobs.first.notes, 'Nota anterior');
      expect(state.errorMessage, contains('Erro ao salvar anotações'));
    });

    test('updates interaction and reloads jobs', () async {
      final interaction = UserJobInteraction(jobId: '1', status: JobStatus.applied);
      when(() => mockRepository.updateJobInteraction(interaction)).thenAnswer((_) async {});
      when(() => mockRepository.getJobs()).thenAnswer((_) async => [testJob1]);

      await cubit.updateInteraction(interaction);

      verify(() => mockRepository.updateJobInteraction(interaction)).called(1);
      verify(() => mockRepository.getJobs()).called(1);
    });
  });
}
