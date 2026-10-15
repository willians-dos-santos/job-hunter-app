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

  void stubRepositoryJobs({
    List<JobItem> newJobs = const [],
    List<JobItem> pipelineJobs = const [],
  }) {
    when(() => mockRepository.getNewJobs(
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
          userId: any(named: 'userId'),
        )).thenAnswer((_) async => newJobs);
    when(() => mockRepository.getActivePipelineJobs(
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
          userId: any(named: 'userId'),
        )).thenAnswer((_) async => pipelineJobs);
    when(() => mockRepository.getJobs(
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
          statusFilter: any(named: 'statusFilter'),
          query: any(named: 'query'),
          userId: any(named: 'userId'),
        )).thenAnswer((_) async => [...newJobs, ...pipelineJobs]);
  }

  setUp(() {
    mockRepository = MockJobsRepository();
    cubit = JobsCubit(mockRepository);
    stubRepositoryJobs();
  });

  tearDown(() {
    cubit.close();
  });

  group('JobsCubit', () {
    test('initial state is JobsInitial', () {
      expect(cubit.state, const JobsInitial());
    });

    test('emits [JobsLoading, JobsLoaded] when loadJobs succeeds and omits archived', () async {
      when(() => mockRepository.getNewJobs(
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
            userId: any(named: 'userId'),
          )).thenAnswer((_) async => [testJob1]);
      when(() => mockRepository.getActivePipelineJobs(
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
            userId: any(named: 'userId'),
          )).thenAnswer((_) async => [testJob2, testArchivedJob]);

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
      expect(loaded.hasMoreNewJobs, isFalse);
    });

    test('loadJobs queries v_new_jobs and v_active_pipeline_jobs in parallel with Future.wait', () async {
      stubRepositoryJobs(newJobs: [testJob1], pipelineJobs: [testJob2]);

      await cubit.loadJobs();

      verify(() => mockRepository.getNewJobs(limit: 20, offset: 0)).called(1);
      verify(() => mockRepository.getActivePipelineJobs()).called(1);
      expect(cubit.state, isA<JobsLoaded>());
    });

    test('loadJobs sets hasMoreNewJobs = true when newJobs batch reaches limit', () async {
      final twentyNewJobs = List.generate(
        20,
        (i) => JobItem(
          jobId: 'new_$i',
          title: 'Vaga Nova $i',
          companyName: 'Empresa $i',
          platform: 'LinkedIn',
          jobUrl: 'https://example.com/new/$i',
          status: JobStatus.newJob,
          createdAt: DateTime.now(),
        ),
      );

      stubRepositoryJobs(newJobs: twentyNewJobs, pipelineJobs: [testJob2]);

      await cubit.loadJobs();

      final state = cubit.state as JobsLoaded;
      expect(state.hasMoreNewJobs, isTrue);
      expect(state.newJobsOffset, 20);
      expect(state.jobsByStatus(JobStatus.newJob).length, 20);
      expect(state.jobsByStatus(JobStatus.applied).length, 1);
    });

    test('loadJobs deduplicates jobs if newJobs contains a job already in pipelineJobs', () async {
      final duplicateJobInNew = testJob2.copyWith(status: JobStatus.newJob);
      stubRepositoryJobs(
        newJobs: [testJob1, duplicateJobInNew],
        pipelineJobs: [testJob2],
      );

      await cubit.loadJobs();

      final state = cubit.state as JobsLoaded;
      expect(state.jobs.length, 2);
      expect(state.jobsByStatus(JobStatus.newJob).length, 1);
      expect(state.jobsByStatus(JobStatus.newJob).first.jobId, '1');
      expect(state.jobsByStatus(JobStatus.applied).length, 1);
      expect(state.jobsByStatus(JobStatus.applied).first.jobId, '2');
    });

    test('emits [JobsLoading, JobsError] when loadJobs fails', () async {
      when(() => mockRepository.getNewJobs(
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
            userId: any(named: 'userId'),
          )).thenThrow(Exception('Network error'));
      when(() => mockRepository.getActivePipelineJobs(
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
            userId: any(named: 'userId'),
          )).thenAnswer((_) async => []);

      final expectedStates = [
        const JobsLoading(),
        isA<JobsError>(),
      ];

      expectLater(cubit.stream, emitsInOrder(expectedStates));

      await cubit.loadJobs();
    });

    test('loadMoreNewJobs incrementally appends new jobs without affecting active pipeline', () async {
      final initialNewJobs = List.generate(
        20,
        (i) => JobItem(
          jobId: 'initial_$i',
          title: 'Vaga Inicial $i',
          companyName: 'Empresa $i',
          platform: 'LinkedIn',
          jobUrl: 'https://example.com/init/$i',
          status: JobStatus.newJob,
          createdAt: DateTime.now(),
        ),
      );

      final nextBatchNewJobs = List.generate(
        5,
        (i) => JobItem(
          jobId: 'next_$i',
          title: 'Vaga Próxima $i',
          companyName: 'Empresa Next $i',
          platform: 'Gupy',
          jobUrl: 'https://example.com/next/$i',
          status: JobStatus.newJob,
          createdAt: DateTime.now(),
        ),
      );

      stubRepositoryJobs(newJobs: initialNewJobs, pipelineJobs: [testJob2]);

      await cubit.loadJobs();
      expect((cubit.state as JobsLoaded).hasMoreNewJobs, isTrue);

      when(() => mockRepository.getNewJobs(limit: 20, offset: 20))
          .thenAnswer((_) async => nextBatchNewJobs);

      await cubit.loadMoreNewJobs();

      final updatedState = cubit.state as JobsLoaded;
      expect(updatedState.hasMoreNewJobs, isFalse); // < 20 returned
      expect(updatedState.newJobsOffset, 25);
      expect(updatedState.jobsByStatus(JobStatus.newJob).length, 25);
      expect(updatedState.jobsByStatus(JobStatus.applied).length, 1);
      expect(updatedState.jobsByStatus(JobStatus.applied).first.jobId, testJob2.jobId);
    });

    test('loadMoreNewJobs ignores calls when already loading or hasMoreNewJobs is false', () async {
      stubRepositoryJobs(newJobs: [testJob1], pipelineJobs: [testJob2]);
      await cubit.loadJobs();

      // hasMoreNewJobs is false because only 1 job was returned (< 20)
      expect((cubit.state as JobsLoaded).hasMoreNewJobs, isFalse);

      await cubit.loadMoreNewJobs();

      // getNewJobs was only called once during initial loadJobs
      verify(() => mockRepository.getNewJobs(limit: 20, offset: 0)).called(1);
    });

    test('loadMoreNewJobs sets newJobsPaginationError on failure and recovers on retry', () async {
      final initialJobs = List.generate(
        20,
        (i) => JobItem(
          jobId: 'init_$i',
          title: 'Vaga $i',
          companyName: 'Empresa $i',
          platform: 'LinkedIn',
          jobUrl: 'https://example.com/$i',
          status: JobStatus.newJob,
          createdAt: DateTime.now(),
        ),
      );
      stubRepositoryJobs(newJobs: initialJobs);

      await cubit.loadJobs();

      when(() => mockRepository.getNewJobs(limit: 20, offset: 20))
          .thenThrow(Exception('Falha de paginação'));

      await cubit.loadMoreNewJobs();

      var state = cubit.state as JobsLoaded;
      expect(state.isLoadingMoreNewJobs, isFalse);
      expect(state.newJobsPaginationError, contains('Falha de paginação'));

      // Retry com sucesso
      when(() => mockRepository.getNewJobs(limit: 20, offset: 20))
          .thenAnswer((_) async => [testJobOnSite]);

      await cubit.loadMoreNewJobs();

      state = cubit.state as JobsLoaded;
      expect(state.newJobsPaginationError, isNull);
      expect(state.jobsByStatus(JobStatus.newJob).length, 21);
    });

    test('optimistically updates job status and calls repository', () async {
      stubRepositoryJobs(newJobs: [testJob1]);
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
      stubRepositoryJobs(newJobs: [testJob1]);
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
      stubRepositoryJobs(newJobs: [testJob1], pipelineJobs: [testJob2]);
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
      stubRepositoryJobs(newJobs: [testJob1], pipelineJobs: [testJob2]);
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
      stubRepositoryJobs(newJobs: [testJob1], pipelineJobs: [testJob2]);
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
      stubRepositoryJobs(
        newJobs: [testJob1, testJobOnSite],
        pipelineJobs: [testJob2],
      );
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
      stubRepositoryJobs(newJobs: [testJob1]);
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
      stubRepositoryJobs(newJobs: [testJob1], pipelineJobs: [testJob2]);
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
      stubRepositoryJobs(newJobs: [testJob1]);
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
      stubRepositoryJobs(newJobs: [jobWithInitialNotes]);
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
      stubRepositoryJobs(newJobs: [testJob1]);

      await cubit.updateInteraction(interaction);

      verify(() => mockRepository.updateJobInteraction(interaction)).called(1);
      verify(() => mockRepository.getNewJobs(limit: 20, offset: 0)).called(1);
      verify(() => mockRepository.getActivePipelineJobs()).called(1);
    });
  });
}
