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

  setUpAll(() {
    registerFallbackValue(
      UserJobInteraction(jobId: 'fallback', status: JobStatus.newJob),
    );
  });

  setUp(() {
    mockDataSource = MockJobRemoteDataSource();
    repository = JobRepository(mockDataSource, 'usr-test-123');
  });

  group('JobRepository', () {
    test('delegates getJobs with default parameters and configured userId', () async {
      when(() => mockDataSource.getJobs(
            limit: 20,
            offset: 0,
            statusFilter: null,
            query: null,
            userId: 'usr-test-123',
          )).thenAnswer((_) async => [testJob]);

      final result = await repository.getJobs();

      expect(result, [testJob]);
      verify(() => mockDataSource.getJobs(
            limit: 20,
            offset: 0,
            statusFilter: null,
            query: null,
            userId: 'usr-test-123',
          )).called(1);
    });

    test('delegates getJobs with custom filters, pagination, and overridden userId', () async {
      when(() => mockDataSource.getJobs(
            limit: 15,
            offset: 30,
            statusFilter: 'interview',
            query: 'Flutter',
            userId: 'custom-user',
          )).thenAnswer((_) async => [testJob]);

      final result = await repository.getJobs(
        limit: 15,
        offset: 30,
        statusFilter: 'interview',
        query: 'Flutter',
        userId: 'custom-user',
      );

      expect(result, [testJob]);
      verify(() => mockDataSource.getJobs(
            limit: 15,
            offset: 30,
            statusFilter: 'interview',
            query: 'Flutter',
            userId: 'custom-user',
          )).called(1);
    });

    test('propagates JobFetchFailure from getJobs', () async {
      when(() => mockDataSource.getJobs(
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
            statusFilter: any(named: 'statusFilter'),
            query: any(named: 'query'),
            userId: any(named: 'userId'),
          )).thenThrow(const JobFetchFailure('Erro de conexão'));

      expect(
        () => repository.getJobs(),
        throwsA(isA<JobFetchFailure>()),
      );
    });

    test('delegates getJobById and returns JobItem', () async {
      when(() => mockDataSource.getJobById('job-1', userId: 'usr-test-123'))
          .thenAnswer((_) async => testJob);

      final result = await repository.getJobById('job-1');

      expect(result, testJob);
      verify(() => mockDataSource.getJobById('job-1', userId: 'usr-test-123')).called(1);
    });

    test('propagates JobNotFoundFailure from getJobById', () async {
      when(() => mockDataSource.getJobById('unknown', userId: any(named: 'userId')))
          .thenThrow(const JobNotFoundFailure('unknown'));

      expect(
        () => repository.getJobById('unknown'),
        throwsA(isA<JobNotFoundFailure>()),
      );
    });

    test('delegates updateJobStatus to datasource with configured userId', () async {
      when(() => mockDataSource.updateJobStatus(
            jobId: 'job-1',
            newStatus: 'interview',
            userId: 'usr-test-123',
          )).thenAnswer((_) async {});

      await repository.updateJobStatus(
        jobId: 'job-1',
        newStatus: 'interview',
      );

      verify(() => mockDataSource.updateJobStatus(
            jobId: 'job-1',
            newStatus: 'interview',
            userId: 'usr-test-123',
          )).called(1);
    });

    test('delegates updateJobStatus with explicit userId override', () async {
      when(() => mockDataSource.updateJobStatus(
            jobId: 'job-1',
            newStatus: 'interview',
            userId: 'override-usr',
          )).thenAnswer((_) async {});

      await repository.updateJobStatus(
        jobId: 'job-1',
        newStatus: 'interview',
        userId: 'override-usr',
      );

      verify(() => mockDataSource.updateJobStatus(
            jobId: 'job-1',
            newStatus: 'interview',
            userId: 'override-usr',
          )).called(1);
    });

    test('propagates JobMutationFailure from updateJobStatus', () async {
      when(() => mockDataSource.updateJobStatus(
            jobId: any(named: 'jobId'),
            newStatus: any(named: 'newStatus'),
            userId: any(named: 'userId'),
          )).thenThrow(const JobMutationFailure('Erro ao atualizar status'));

      expect(
        () => repository.updateJobStatus(jobId: 'job-1', newStatus: 'offer'),
        throwsA(isA<JobMutationFailure>()),
      );
    });

    test('delegates updateJobNotes to datasource with configured userId', () async {
      when(() => mockDataSource.updateJobNotes(
            jobId: 'job-1',
            notes: 'Anotações importantes',
            userId: 'usr-test-123',
          )).thenAnswer((_) async {});

      await repository.updateJobNotes(
        jobId: 'job-1',
        notes: 'Anotações importantes',
      );

      verify(() => mockDataSource.updateJobNotes(
            jobId: 'job-1',
            notes: 'Anotações importantes',
            userId: 'usr-test-123',
          )).called(1);
    });

    test('delegates toggleJobArchived to datasource with configured userId', () async {
      when(() => mockDataSource.toggleJobArchived(
            jobId: 'job-1',
            isArchived: true,
            userId: 'usr-test-123',
          )).thenAnswer((_) async {});

      await repository.toggleJobArchived(
        jobId: 'job-1',
        isArchived: true,
      );

      verify(() => mockDataSource.toggleJobArchived(
            jobId: 'job-1',
            isArchived: true,
            userId: 'usr-test-123',
          )).called(1);
    });

    test('delegates updateJobInteraction to datasource ensuring userId is populated', () async {
      final interaction = UserJobInteraction(
        jobId: 'job-1',
        status: JobStatus.applied,
      );

      when(() => mockDataSource.upsertInteraction(
            any(),
            userId: any(named: 'userId'),
          )).thenAnswer((_) async {});

      await repository.updateJobInteraction(interaction);

      final captured = verify(() => mockDataSource.upsertInteraction(
            captureAny(),
            userId: 'usr-test-123',
          )).captured;

      expect(captured.first, isA<UserJobInteraction>());
      expect((captured.first as UserJobInteraction).userId, 'usr-test-123');
    });
  });
}
