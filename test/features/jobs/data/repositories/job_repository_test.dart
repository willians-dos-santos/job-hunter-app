import 'package:flutter_test/flutter_test.dart';
import 'package:job_hunter_app/core/errors/job_failure.dart';
import 'package:job_hunter_app/features/jobs/data/datasources/job_remote_datasource.dart';
import 'package:job_hunter_app/features/jobs/data/repositories/job_repository_impl.dart';
import 'package:job_hunter_app/features/jobs/domain/models/job_item.dart';
import 'package:job_hunter_app/features/jobs/domain/models/job_status.dart';
import 'package:job_hunter_app/features/jobs/domain/models/user_job_interaction.dart';
import 'package:mocktail/mocktail.dart';

class MockJobRemoteDataSource extends Mock implements IJobRemoteDataSource {}

void main() {
  late MockJobRemoteDataSource mockDataSource;
  late JobRepository repository;

  final testJob = JobItem(
    jobId: 'job-1',
    title: 'Flutter Dev',
    companyName: 'Acme',
    platform: 'LinkedIn',
    jobUrl: 'https://example.com',
    status: JobStatus.newJob,
    createdAt: DateTime.now(),
  );

  setUp(() {
    mockDataSource = MockJobRemoteDataSource();
    repository = JobRepository(mockDataSource);
  });

  group('JobRepository', () {
    test('delegates getJobs with default parameters', () async {
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

    test('delegates getJobs with custom filters and pagination', () async {
      when(() => mockDataSource.getJobs(
            limit: 15,
            offset: 30,
            statusFilter: 'interview',
            query: 'Flutter',
          )).thenAnswer((_) async => [testJob]);

      final result = await repository.getJobs(
        limit: 15,
        offset: 30,
        statusFilter: 'interview',
        query: 'Flutter',
      );

      expect(result, [testJob]);
      verify(() => mockDataSource.getJobs(
            limit: 15,
            offset: 30,
            statusFilter: 'interview',
            query: 'Flutter',
          )).called(1);
    });

    test('propagates JobFetchFailure from getJobs', () async {
      when(() => mockDataSource.getJobs(
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
            statusFilter: any(named: 'statusFilter'),
            query: any(named: 'query'),
          )).thenThrow(const JobFetchFailure('Erro de conexão'));

      expect(
        () => repository.getJobs(),
        throwsA(isA<JobFetchFailure>()),
      );
    });

    test('delegates getJobById and returns JobItem', () async {
      when(() => mockDataSource.getJobById('job-1'))
          .thenAnswer((_) async => testJob);

      final result = await repository.getJobById('job-1');

      expect(result, testJob);
      verify(() => mockDataSource.getJobById('job-1')).called(1);
    });

    test('propagates JobNotFoundFailure from getJobById', () async {
      when(() => mockDataSource.getJobById('unknown'))
          .thenThrow(const JobNotFoundFailure('unknown'));

      expect(
        () => repository.getJobById('unknown'),
        throwsA(isA<JobNotFoundFailure>()),
      );
    });

    test('delegates updateJobStatus to datasource', () async {
      when(() => mockDataSource.updateJobStatus(
            jobId: 'job-1',
            newStatus: 'interview',
          )).thenAnswer((_) async {});

      await repository.updateJobStatus(
        jobId: 'job-1',
        newStatus: 'interview',
      );

      verify(() => mockDataSource.updateJobStatus(
            jobId: 'job-1',
            newStatus: 'interview',
          )).called(1);
    });

    test('propagates JobMutationFailure from updateJobStatus', () async {
      when(() => mockDataSource.updateJobStatus(
            jobId: any(named: 'jobId'),
            newStatus: any(named: 'newStatus'),
          )).thenThrow(const JobMutationFailure('Erro ao atualizar status'));

      expect(
        () => repository.updateJobStatus(jobId: 'job-1', newStatus: 'offer'),
        throwsA(isA<JobMutationFailure>()),
      );
    });

    test('delegates updateJobNotes to datasource', () async {
      when(() => mockDataSource.updateJobNotes(
            jobId: 'job-1',
            notes: 'Anotações importantes',
          )).thenAnswer((_) async {});

      await repository.updateJobNotes(
        jobId: 'job-1',
        notes: 'Anotações importantes',
      );

      verify(() => mockDataSource.updateJobNotes(
            jobId: 'job-1',
            notes: 'Anotações importantes',
          )).called(1);
    });

    test('delegates toggleJobArchived to datasource', () async {
      when(() => mockDataSource.toggleJobArchived(
            jobId: 'job-1',
            isArchived: true,
          )).thenAnswer((_) async {});

      await repository.toggleJobArchived(
        jobId: 'job-1',
        isArchived: true,
      );

      verify(() => mockDataSource.toggleJobArchived(
            jobId: 'job-1',
            isArchived: true,
          )).called(1);
    });

    test('delegates updateJobInteraction to datasource', () async {
      final interaction = UserJobInteraction(
        jobId: 'job-1',
        status: JobStatus.applied,
      );

      when(() => mockDataSource.upsertInteraction(interaction))
          .thenAnswer((_) async {});

      await repository.updateJobInteraction(interaction);

      verify(() => mockDataSource.upsertInteraction(interaction)).called(1);
    });
  });
}
