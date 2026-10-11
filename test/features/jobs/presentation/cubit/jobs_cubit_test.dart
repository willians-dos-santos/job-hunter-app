import 'package:flutter_test/flutter_test.dart';
import 'package:job_hunter_app/features/jobs/domain/models/job_item.dart';
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

  final testJob = JobItem(
    jobId: '1',
    title: 'Flutter Dev',
    companyName: 'Acme',
    platform: 'LinkedIn',
    jobUrl: 'https://example.com',
    status: JobStatus.newJob,
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

    test('emits [JobsLoading, JobsLoaded] when loadJobs succeeds', () async {
      when(() => mockRepository.getJobs()).thenAnswer((_) async => [testJob]);

      final expectedStates = [
        const JobsLoading(),
        JobsLoaded([testJob]),
      ];

      expectLater(cubit.stream, emitsInOrder(expectedStates));

      await cubit.loadJobs();
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

    test('updates interaction and reloads jobs', () async {
      final interaction = UserJobInteraction(jobId: '1', status: JobStatus.applied);
      when(() => mockRepository.updateJobInteraction(interaction)).thenAnswer((_) async {});
      when(() => mockRepository.getJobs()).thenAnswer((_) async => [testJob]);

      await cubit.updateInteraction(interaction);

      verify(() => mockRepository.updateJobInteraction(interaction)).called(1);
      verify(() => mockRepository.getJobs()).called(1);
    });
  });
}
