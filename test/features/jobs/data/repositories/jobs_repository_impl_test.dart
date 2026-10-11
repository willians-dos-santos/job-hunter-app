import 'package:flutter_test/flutter_test.dart';
import 'package:job_hunter_app/features/jobs/data/datasources/jobs_remote_datasource.dart';
import 'package:job_hunter_app/features/jobs/data/repositories/jobs_repository_impl.dart';
import 'package:job_hunter_app/features/jobs/domain/models/job_item.dart';
import 'package:job_hunter_app/features/jobs/domain/models/job_status.dart';
import 'package:job_hunter_app/features/jobs/domain/models/user_job_interaction.dart';
import 'package:mocktail/mocktail.dart';

class MockJobsRemoteDataSource extends Mock implements JobsRemoteDataSource {}

void main() {
  late MockJobsRemoteDataSource mockDataSource;
  late JobsRepositoryImpl repository;

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
    mockDataSource = MockJobsRemoteDataSource();
    repository = JobsRepositoryImpl(mockDataSource);
  });

  group('JobsRepositoryImpl (backwards compatibility)', () {
    test('delegates getJobs to datasource', () async {
      when(() => mockDataSource.getJobs(
            limit: 20,
            offset: 0,
            statusFilter: null,
            query: null,
          )).thenAnswer((_) async => [testJob]);

      final result = await repository.getJobs();

      expect(result, [testJob]);
      verify(() => mockDataSource.getJobs(
            limit: 20,
            offset: 0,
            statusFilter: null,
            query: null,
          )).called(1);
    });

    test('delegates getJobById to datasource', () async {
      when(() => mockDataSource.getJobById('1'))
          .thenAnswer((_) async => testJob);

      final result = await repository.getJobById('1');

      expect(result, testJob);
      verify(() => mockDataSource.getJobById('1')).called(1);
    });

    test('delegates updateJobInteraction to datasource', () async {
      final interaction = UserJobInteraction(
        jobId: '1',
        status: JobStatus.applied,
      );

      when(() => mockDataSource.upsertInteraction(interaction))
          .thenAnswer((_) async {});

      await repository.updateJobInteraction(interaction);

      verify(() => mockDataSource.upsertInteraction(interaction)).called(1);
    });
  });
}
