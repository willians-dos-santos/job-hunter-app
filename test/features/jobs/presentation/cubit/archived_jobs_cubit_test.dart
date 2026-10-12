import 'package:flutter_test/flutter_test.dart';
import 'package:job_hunter_app/core/errors/job_failure.dart';
import 'package:job_hunter_app/features/jobs/domain/models/job_item.dart';
import 'package:job_hunter_app/features/jobs/domain/models/job_status.dart';
import 'package:job_hunter_app/features/jobs/domain/repositories/job_repository.dart';
import 'package:job_hunter_app/features/jobs/presentation/cubit/archived_jobs_cubit.dart';
import 'package:job_hunter_app/features/jobs/presentation/cubit/archived_jobs_state.dart';
import 'package:mocktail/mocktail.dart';

class MockJobRepository extends Mock implements IJobRepository {}

void main() {
  late MockJobRepository mockRepository;
  late ArchivedJobsCubit cubit;

  final job1 = JobItem(
    jobId: 'job-1',
    title: 'Engenheiro Flutter',
    companyName: 'TechCorp',
    platform: 'LinkedIn',
    jobUrl: 'https://techcorp.com/jobs/1',
    status: JobStatus.rejected,
    isArchived: true,
  );

  final job2 = JobItem(
    jobId: 'job-2',
    title: 'Senior Mobile Dev',
    companyName: 'Startup Inc',
    platform: 'Gupy',
    jobUrl: 'https://startup.com/jobs/2',
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

  group('ArchivedJobsCubit', () {
    test('initial state is ArchivedJobsInitial and repository is exposed', () {
      expect(cubit.state, const ArchivedJobsInitial());
      expect(cubit.repository, mockRepository);
    });

    test('emits [ArchivedJobsLoading, ArchivedJobsLoaded] on successful loadArchivedJobs', () async {
      when(() => mockRepository.getArchivedJobs())
          .thenAnswer((_) async => [job1, job2]);

      final expectedStates = [
        const ArchivedJobsLoading(),
        ArchivedJobsLoaded([job1, job2]),
      ];

      expectLater(cubit.stream, emitsInOrder(expectedStates));

      await cubit.loadArchivedJobs();
      expect(cubit.state, ArchivedJobsLoaded([job1, job2]));
      verify(() => mockRepository.getArchivedJobs()).called(1);
    });

    test('emits [ArchivedJobsLoading, ArchivedJobsLoaded] with empty list when no archived jobs found', () async {
      when(() => mockRepository.getArchivedJobs())
          .thenAnswer((_) async => <JobItem>[]);

      final expectedStates = [
        const ArchivedJobsLoading(),
        const ArchivedJobsLoaded([]),
      ];

      expectLater(cubit.stream, emitsInOrder(expectedStates));

      await cubit.loadArchivedJobs();
      expect(cubit.state, const ArchivedJobsLoaded([]));
    });

    test('emits [ArchivedJobsLoading, ArchivedJobsError] on repository failure', () async {
      when(() => mockRepository.getArchivedJobs())
          .thenThrow(const JobFetchFailure('Erro de conexão ao banco'));

      final expectedStates = [
        const ArchivedJobsLoading(),
        isA<ArchivedJobsError>().having(
          (s) => s.message,
          'message',
          contains('Erro de conexão ao banco'),
        ),
      ];

      expectLater(cubit.stream, emitsInOrder(expectedStates));

      await cubit.loadArchivedJobs();
      expect(cubit.state, isA<ArchivedJobsError>());
    });

    group('restoreJob', () {
      test('optimistically removes job, calls toggleJobArchived with isArchived: false, and emits success message', () async {
        when(() => mockRepository.getArchivedJobs())
            .thenAnswer((_) async => [job1, job2]);
        when(() => mockRepository.toggleJobArchived(
              jobId: 'job-1',
              isArchived: false,
            )).thenAnswer((_) async {});

        await cubit.loadArchivedJobs();

        final expectedStates = [
          ArchivedJobsLoaded([job2]),
          ArchivedJobsLoaded(
            [job2],
            successMessage: 'Vaga restaurada com sucesso.',
          ),
        ];

        expectLater(cubit.stream, emitsInOrder(expectedStates));

        await cubit.restoreJob('job-1');

        verify(() => mockRepository.toggleJobArchived(
              jobId: 'job-1',
              isArchived: false,
            )).called(1);
      });

      test('rolls back to previous list and emits errorMessage when restore fails', () async {
        when(() => mockRepository.getArchivedJobs())
            .thenAnswer((_) async => [job1, job2]);
        when(() => mockRepository.toggleJobArchived(
              jobId: 'job-1',
              isArchived: false,
            )).thenThrow(const JobMutationFailure('Falha ao restaurar no Supabase'));

        await cubit.loadArchivedJobs();

        final expectedStates = [
          ArchivedJobsLoaded([job2]),
          isA<ArchivedJobsLoaded>()
              .having((s) => s.jobs, 'jobs', [job1, job2])
              .having((s) => s.errorMessage, 'errorMessage',
                  contains('Falha ao restaurar no Supabase')),
        ];

        expectLater(cubit.stream, emitsInOrder(expectedStates));

        await cubit.restoreJob('job-1');
      });

      test('does nothing when current state is not ArchivedJobsLoaded', () async {
        await cubit.restoreJob('job-1');
        expect(cubit.state, const ArchivedJobsInitial());
      });
    });

    group('transient message clears', () {
      test('clears error message via clearErrorMessage', () async {
        when(() => mockRepository.getArchivedJobs())
            .thenAnswer((_) async => [job1]);
        when(() => mockRepository.toggleJobArchived(
              jobId: 'job-1',
              isArchived: false,
            )).thenThrow(const JobMutationFailure('Falha'));

        await cubit.loadArchivedJobs();
        await cubit.restoreJob('job-1');

        expect(
          (cubit.state as ArchivedJobsLoaded).errorMessage,
          isNotNull,
        );

        cubit.clearErrorMessage();

        expect(
          (cubit.state as ArchivedJobsLoaded).errorMessage,
          isNull,
        );
      });

      test('clears success message via clearSuccessMessage', () async {
        when(() => mockRepository.getArchivedJobs())
            .thenAnswer((_) async => [job1]);
        when(() => mockRepository.toggleJobArchived(
              jobId: 'job-1',
              isArchived: false,
            )).thenAnswer((_) async {});

        await cubit.loadArchivedJobs();
        await cubit.restoreJob('job-1');

        expect(
          (cubit.state as ArchivedJobsLoaded).successMessage,
          isNotNull,
        );

        cubit.clearSuccessMessage();

        expect(
          (cubit.state as ArchivedJobsLoaded).successMessage,
          isNull,
        );
      });
    });
  });
}
