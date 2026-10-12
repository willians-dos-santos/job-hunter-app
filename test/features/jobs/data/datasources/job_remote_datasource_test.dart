import 'package:flutter_test/flutter_test.dart';
import 'package:job_hunter_app/core/constants/app_constants.dart';
import 'package:job_hunter_app/core/errors/job_failure.dart';
import 'package:job_hunter_app/features/jobs/data/datasources/job_remote_datasource.dart';
import 'package:job_hunter_app/features/jobs/domain/models/job_status.dart';
import 'package:job_hunter_app/features/jobs/domain/models/user_job_interaction.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../helpers/supabase_test_fakes.dart';

void main() {
  late MockSupabaseClient mockClient;
  late MockSupabaseQueryBuilder mockQueryBuilder;
  late JobRemoteDataSource dataSource;

  final sampleJobJson = <String, dynamic>{
    'job_id': 'job-123',
    'title': 'Senior Flutter Engineer',
    'company_name': 'Tech Corp',
    'platform': 'LinkedIn',
    'job_url': 'https://linkedin.com/jobs/123',
    'location': 'Remoto - Brasil',
    'salary_text': 'R\$ 15.000',
    'status': 'new',
    'notes': null,
    'applied_at': null,
    'published_at': '2026-10-10T08:00:00.000Z',
    'created_at': '2026-10-10T10:00:00.000Z',
    'is_archived': false,
  };

  setUp(() {
    mockClient = MockSupabaseClient();
    mockQueryBuilder = MockSupabaseQueryBuilder();
    dataSource = JobRemoteDataSource(mockClient, 'usr-test-123');

    when(() => mockClient.from(any())).thenAnswer((_) => mockQueryBuilder);
  });

  group('JobRemoteDataSource - getJobs', () {
    test('fetches jobs list with default parameters successfully', () async {
      int? capturedFrom;
      int? capturedTo;
      String? capturedOrderCol;
      bool? capturedAscending;

      final fakeBuilder = FakePostgrestFilterBuilder<List<Map<String, dynamic>>>(
        data: [sampleJobJson],
        onOrder: (col, asc) {
          capturedOrderCol = col;
          capturedAscending = asc;
        },
        onRange: (from, to) {
          capturedFrom = from;
          capturedTo = to;
        },
      );

      when(() => mockQueryBuilder.select()).thenAnswer((_) => fakeBuilder);

      final jobs = await dataSource.getJobs();

      expect(jobs.length, 1);
      expect(jobs.first.jobId, 'job-123');
      expect(jobs.first.title, 'Senior Flutter Engineer');
      expect(jobs.first.companyName, 'Tech Corp');
      expect(capturedFrom, 0);
      expect(capturedTo, 19);
      expect(capturedOrderCol, 'published_at');
      expect(capturedAscending, isFalse);
      verify(() => mockClient.from(AppConstants.userJobsView)).called(1);
    });

    test('supports custom pagination offset and limit', () async {
      int? capturedFrom;
      int? capturedTo;

      final fakeBuilder = FakePostgrestFilterBuilder<List<Map<String, dynamic>>>(
        data: [sampleJobJson],
        onRange: (from, to) {
          capturedFrom = from;
          capturedTo = to;
        },
      );

      when(() => mockQueryBuilder.select()).thenAnswer((_) => fakeBuilder);

      final jobs = await dataSource.getJobs(limit: 10, offset: 20);

      expect(jobs.length, 1);
      expect(capturedFrom, 20);
      expect(capturedTo, 29);
    });

    test('applies user_id filter allowing null (unclaimed) and current user records', () async {
      String? capturedOr;

      final fakeBuilder = FakePostgrestFilterBuilder<List<Map<String, dynamic>>>(
        data: [sampleJobJson],
        onOr: (filters) {
          capturedOr = filters;
        },
      );

      when(() => mockQueryBuilder.select()).thenAnswer((_) => fakeBuilder);

      await dataSource.getJobs();

      expect(capturedOr, 'user_id.is.null,user_id.eq.usr-test-123');
    });

    test('overrides configured user_id in or filter when explicit userId parameter is passed to getJobs', () async {
      String? capturedOr;

      final fakeBuilder = FakePostgrestFilterBuilder<List<Map<String, dynamic>>>(
        data: [sampleJobJson],
        onOr: (filters) {
          capturedOr = filters;
        },
      );

      when(() => mockQueryBuilder.select()).thenAnswer((_) => fakeBuilder);

      await dataSource.getJobs(userId: 'custom-override-id');

      expect(capturedOr, 'user_id.is.null,user_id.eq.custom-override-id');
    });

    test('applies status filter when statusFilter is provided', () async {
      String? capturedStatusCol;
      Object? capturedStatusVal;
      String? capturedOr;

      final fakeBuilder = FakePostgrestFilterBuilder<List<Map<String, dynamic>>>(
        data: [sampleJobJson],
        onEq: (col, val) {
          capturedStatusCol = col;
          capturedStatusVal = val;
        },
        onOr: (filters) {
          capturedOr = filters;
        },
      );

      when(() => mockQueryBuilder.select()).thenAnswer((_) => fakeBuilder);

      await dataSource.getJobs(statusFilter: 'applied');

      expect(capturedStatusCol, 'status');
      expect(capturedStatusVal, 'applied');
      expect(capturedOr, 'user_id.is.null,user_id.eq.usr-test-123');
    });

    test('applies text search filter on title and company when query is provided', () async {
      final capturedOrFilters = <String>[];

      final fakeBuilder = FakePostgrestFilterBuilder<List<Map<String, dynamic>>>(
        data: [sampleJobJson],
        onOr: (filters) {
          capturedOrFilters.add(filters);
        },
      );

      when(() => mockQueryBuilder.select()).thenAnswer((_) => fakeBuilder);

      await dataSource.getJobs(query: 'Flutter');

      expect(
        capturedOrFilters.any((f) =>
            f.contains('title.ilike.%Flutter%') &&
            f.contains('company.ilike.%Flutter%')),
        isTrue,
      );
    });

    test('returns empty list when no jobs found', () async {
      final fakeBuilder = FakePostgrestFilterBuilder<List<Map<String, dynamic>>>(
        data: [],
      );

      when(() => mockQueryBuilder.select()).thenAnswer((_) => fakeBuilder);

      final jobs = await dataSource.getJobs();

      expect(jobs, isEmpty);
    });

    test('wraps PostgrestException into JobFetchFailure', () async {
      final fakeBuilder = FakePostgrestFilterBuilder<List<Map<String, dynamic>>>(
        error: const PostgrestException(
          message: 'Connection terminated',
          code: 'P0001',
        ),
      );

      when(() => mockQueryBuilder.select()).thenAnswer((_) => fakeBuilder);

      expect(
        () => dataSource.getJobs(),
        throwsA(isA<JobFetchFailure>()
            .having((e) => e.message, 'message', 'Connection terminated')
            .having((e) => e.code, 'code', 'P0001')),
      );
    });

    test('wraps generic exceptions into JobFetchFailure', () async {
      final fakeBuilder = FakePostgrestFilterBuilder<List<Map<String, dynamic>>>(
        error: Exception('Socket timeout'),
      );

      when(() => mockQueryBuilder.select()).thenAnswer((_) => fakeBuilder);

      expect(
        () => dataSource.getJobs(),
        throwsA(isA<JobFetchFailure>()
            .having((e) => e.message, 'message', contains('Socket timeout'))),
      );
    });

    test('fetchJobs alias delegates correctly', () async {
      final fakeBuilder = FakePostgrestFilterBuilder<List<Map<String, dynamic>>>(
        data: [sampleJobJson],
      );

      when(() => mockQueryBuilder.select()).thenAnswer((_) => fakeBuilder);

      final jobs = await dataSource.fetchJobs(limit: 5, offset: 0);
      expect(jobs.length, 1);
    });
  });

  group('JobRemoteDataSource - getJobById', () {
    test('returns JobItem when record is found', () async {
      String? capturedCol;
      Object? capturedVal;
      String? capturedOr;

      final fakeBuilder = FakePostgrestFilterBuilder<List<Map<String, dynamic>>>(
        data: [sampleJobJson],
        onEq: (col, val) {
          capturedCol = col;
          capturedVal = val;
        },
        onOr: (filters) {
          capturedOr = filters;
        },
      );

      when(() => mockQueryBuilder.select()).thenAnswer((_) => fakeBuilder);

      final job = await dataSource.getJobById('job-123');

      expect(job.jobId, 'job-123');
      expect(job.title, 'Senior Flutter Engineer');
      expect(capturedCol, 'job_id');
      expect(capturedVal, 'job-123');
      expect(capturedOr, 'user_id.is.null,user_id.eq.usr-test-123');
    });

    test('throws JobNotFoundFailure when record is null', () async {
      final fakeBuilder = FakePostgrestFilterBuilder<List<Map<String, dynamic>>>(
        data: [],
      );

      when(() => mockQueryBuilder.select()).thenAnswer((_) => fakeBuilder);

      expect(
        () => dataSource.getJobById('unknown-id'),
        throwsA(isA<JobNotFoundFailure>()
            .having((e) => e.message, 'message', contains('unknown-id'))),
      );
    });

    test('wraps PostgrestException into JobFetchFailure', () async {
      final fakeBuilder = FakePostgrestFilterBuilder<List<Map<String, dynamic>>>(
        error: const PostgrestException(message: 'Database error', code: '500'),
      );

      when(() => mockQueryBuilder.select()).thenAnswer((_) => fakeBuilder);

      expect(
        () => dataSource.getJobById('job-123'),
        throwsA(isA<JobFetchFailure>()),
      );
    });

    test('fetchJobById alias delegates correctly', () async {
      final fakeBuilder = FakePostgrestFilterBuilder<List<Map<String, dynamic>>>(
        data: [sampleJobJson],
      );

      when(() => mockQueryBuilder.select()).thenAnswer((_) => fakeBuilder);

      final job = await dataSource.fetchJobById('job-123');
      expect(job?.jobId, 'job-123');
    });
  });

  group('JobRemoteDataSource - updateJobStatus', () {
    test('upserts status change payload with onConflict user_id,job_id', () async {
      dynamic capturedPayload;
      String? capturedConflict;

      final fakeUpsert = FakePostgrestFilterBuilder<void>(data: null);

      when(() => mockQueryBuilder.upsert(
            any(),
            onConflict: any(named: 'onConflict'),
          )).thenAnswer((invocation) {
        capturedPayload = invocation.positionalArguments[0];
        capturedConflict = invocation.namedArguments[#onConflict] as String?;
        return fakeUpsert;
      });

      await dataSource.updateJobStatus(
        jobId: 'job-123',
        newStatus: 'interview',
      );

      expect(capturedPayload, {
        'job_id': 'job-123',
        'user_id': 'usr-test-123',
        'status': 'interviewing',
      });
      expect(capturedConflict, 'user_id,job_id');
      verify(() => mockClient.from(AppConstants.userJobInteractionsTable)).called(1);
    });

    test('resolves user_id from auth.currentUser?.id when configuredUserId is null', () async {
      final mockAuth = MockGoTrueClient();
      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn('auth-user-999');
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockClient.auth).thenReturn(mockAuth);

      final ds = JobRemoteDataSource(mockClient, null);

      dynamic capturedPayload;
      String? capturedConflict;
      final fakeUpsert = FakePostgrestFilterBuilder<void>(data: null);
      when(() => mockQueryBuilder.upsert(
            any(),
            onConflict: any(named: 'onConflict'),
          )).thenAnswer((invocation) {
        capturedPayload = invocation.positionalArguments[0];
        capturedConflict = invocation.namedArguments[#onConflict] as String?;
        return fakeUpsert;
      });

      await ds.updateJobStatus(
        jobId: 'job-123',
        newStatus: 'offer',
      );

      expect(capturedPayload['user_id'], 'auth-user-999');
      expect(capturedPayload['status'], 'offer');
      expect(capturedConflict, 'user_id,job_id');
    });

    test('includes applied_at timestamp when status transitions to applied', () async {
      dynamic capturedPayload;

      final fakeUpsert = FakePostgrestFilterBuilder<void>(data: null);

      when(() => mockQueryBuilder.upsert(
            any(),
            onConflict: any(named: 'onConflict'),
          )).thenAnswer((invocation) {
        capturedPayload = invocation.positionalArguments[0];
        return fakeUpsert;
      });

      await dataSource.updateJobStatus(
        jobId: 'job-123',
        newStatus: 'applied',
      );

      expect(capturedPayload['job_id'], 'job-123');
      expect(capturedPayload['user_id'], 'usr-test-123');
      expect(capturedPayload['status'], 'applied');
      expect(capturedPayload['applied_at'], isNotNull);
    });

    test('wraps PostgrestException into JobMutationFailure', () async {
      final fakeUpsert = FakePostgrestFilterBuilder<void>(
        error: const PostgrestException(message: 'Mutation failed', code: '400'),
      );

      when(() => mockQueryBuilder.upsert(
            any(),
            onConflict: any(named: 'onConflict'),
          )).thenAnswer((_) => fakeUpsert);

      expect(
        () => dataSource.updateJobStatus(
          jobId: 'job-123',
          newStatus: 'interview',
        ),
        throwsA(isA<JobMutationFailure>()
            .having((e) => e.message, 'message', 'Mutation failed')),
      );
    });

    test('wraps generic exceptions into JobMutationFailure', () async {
      final fakeUpsert = FakePostgrestFilterBuilder<void>(
        error: Exception('Network dropped'),
      );

      when(() => mockQueryBuilder.upsert(
            any(),
            onConflict: any(named: 'onConflict'),
          )).thenAnswer((_) => fakeUpsert);

      expect(
        () => dataSource.updateJobStatus(
          jobId: 'job-123',
          newStatus: 'interview',
        ),
        throwsA(isA<JobMutationFailure>()
            .having((e) => e.message, 'message', contains('Network dropped'))),
      );
    });
  });

  group('JobRemoteDataSource - updateJobNotes', () {
    test('upserts notes payload with onConflict user_id,job_id', () async {
      dynamic capturedPayload;
      String? capturedConflict;

      final fakeUpsert = FakePostgrestFilterBuilder<void>(data: null);

      when(() => mockQueryBuilder.upsert(
            any(),
            onConflict: any(named: 'onConflict'),
          )).thenAnswer((invocation) {
        capturedPayload = invocation.positionalArguments[0];
        capturedConflict = invocation.namedArguments[#onConflict] as String?;
        return fakeUpsert;
      });

      await dataSource.updateJobNotes(
        jobId: 'job-123',
        notes: 'Feedback positivo na primeira fase',
      );

      expect(capturedPayload, {
        'job_id': 'job-123',
        'user_id': 'usr-test-123',
        'notes': 'Feedback positivo na primeira fase',
      });
      expect(capturedConflict, 'user_id,job_id');
      verify(() => mockClient.from(AppConstants.userJobInteractionsTable)).called(1);
    });

    test('wraps PostgrestException into JobMutationFailure', () async {
      final fakeUpsert = FakePostgrestFilterBuilder<void>(
        error: const PostgrestException(message: 'Notes error', code: '500'),
      );

      when(() => mockQueryBuilder.upsert(
            any(),
            onConflict: any(named: 'onConflict'),
          )).thenAnswer((_) => fakeUpsert);

      expect(
        () => dataSource.updateJobNotes(
          jobId: 'job-123',
          notes: 'Test notes',
        ),
        throwsA(isA<JobMutationFailure>()),
      );
    });
  });

  group('JobRemoteDataSource - toggleJobArchived', () {
    test('upserts status: archived payload with onConflict user_id,job_id', () async {
      dynamic capturedPayload;
      String? capturedConflict;

      final fakeUpsert = FakePostgrestFilterBuilder<void>(data: null);

      when(() => mockQueryBuilder.upsert(
            any(),
            onConflict: any(named: 'onConflict'),
          )).thenAnswer((invocation) {
        capturedPayload = invocation.positionalArguments[0];
        capturedConflict = invocation.namedArguments[#onConflict] as String?;
        return fakeUpsert;
      });

      await dataSource.toggleJobArchived(
        jobId: 'job-123',
        isArchived: true,
      );

      expect(capturedPayload, {
        'job_id': 'job-123',
        'user_id': 'usr-test-123',
        'status': 'archived',
      });
      expect(capturedConflict, 'user_id,job_id');
      verify(() => mockClient.from(AppConstants.userJobInteractionsTable)).called(1);
    });

    test('upserts status: new payload when isArchived is false with onConflict user_id,job_id', () async {
      dynamic capturedPayload;
      String? capturedConflict;

      final fakeUpsert = FakePostgrestFilterBuilder<void>(data: null);

      when(() => mockQueryBuilder.upsert(
            any(),
            onConflict: any(named: 'onConflict'),
          )).thenAnswer((invocation) {
        capturedPayload = invocation.positionalArguments[0];
        capturedConflict = invocation.namedArguments[#onConflict] as String?;
        return fakeUpsert;
      });

      await dataSource.toggleJobArchived(
        jobId: 'job-123',
        isArchived: false,
      );

      expect(capturedPayload, {
        'job_id': 'job-123',
        'user_id': 'usr-test-123',
        'status': 'new',
      });
      expect(capturedConflict, 'user_id,job_id');
    });

    test('wraps PostgrestException into JobMutationFailure', () async {
      final fakeUpsert = FakePostgrestFilterBuilder<void>(
        error: const PostgrestException(message: 'Archive error', code: '500'),
      );

      when(() => mockQueryBuilder.upsert(
            any(),
            onConflict: any(named: 'onConflict'),
          )).thenAnswer((_) => fakeUpsert);

      expect(
        () => dataSource.toggleJobArchived(
          jobId: 'job-123',
          isArchived: true,
        ),
        throwsA(isA<JobMutationFailure>()),
      );
    });
  });

  group('JobRemoteDataSource - getArchivedJobs', () {
    test('queries v_user_jobs with status: archived successfully', () async {
      String? capturedEqualCol;
      dynamic capturedEqualVal;

      final fakeBuilder = FakePostgrestFilterBuilder<List<Map<String, dynamic>>>(
        data: [sampleJobJson],
        onEq: (col, val) {
          capturedEqualCol = col;
          capturedEqualVal = val;
        },
      );

      when(() => mockQueryBuilder.select()).thenAnswer((_) => fakeBuilder);

      final result = await dataSource.getArchivedJobs();

      expect(result.length, 1);
      expect(capturedEqualCol, 'status');
      expect(capturedEqualVal, 'archived');
      verify(() => mockClient.from(AppConstants.userJobsView)).called(1);
    });

    test('propagates PostgrestException as JobFetchFailure', () async {
      final fakeBuilder = FakePostgrestFilterBuilder<List<Map<String, dynamic>>>(
        error: const PostgrestException(message: 'Query error', code: '400'),
      );

      when(() => mockQueryBuilder.select()).thenAnswer((_) => fakeBuilder);

      expect(
        () => dataSource.getArchivedJobs(),
        throwsA(isA<JobFetchFailure>()),
      );
    });
  });

  group('JobRemoteDataSource - upsertInteraction', () {
    test('upserts interaction model payload with onConflict user_id,job_id', () async {
      dynamic capturedPayload;
      String? capturedConflict;

      final fakeUpsert = FakePostgrestFilterBuilder<void>(data: null);

      when(() => mockQueryBuilder.upsert(
            any(),
            onConflict: any(named: 'onConflict'),
          )).thenAnswer((invocation) {
        capturedPayload = invocation.positionalArguments[0];
        capturedConflict = invocation.namedArguments[#onConflict] as String?;
        return fakeUpsert;
      });

      final interaction = UserJobInteraction(
        jobId: 'job-123',
        status: JobStatus.offer,
        notes: 'Oferta final recebida',
      );

      await dataSource.upsertInteraction(interaction);

      expect(capturedPayload['job_id'], 'job-123');
      expect(capturedPayload['user_id'], 'usr-test-123');
      expect(capturedPayload['status'], 'offer');
      expect(capturedPayload['notes'], 'Oferta final recebida');
      expect(capturedConflict, 'user_id,job_id');
    });

    test('wraps PostgrestException into JobMutationFailure', () async {
      final fakeUpsert = FakePostgrestFilterBuilder<void>(
        error: const PostgrestException(message: 'Upsert error', code: '500'),
      );

      when(() => mockQueryBuilder.upsert(
            any(),
            onConflict: any(named: 'onConflict'),
          )).thenAnswer((_) => fakeUpsert);

      final interaction = UserJobInteraction(
        jobId: 'job-123',
        status: JobStatus.rejected,
      );

      expect(
        () => dataSource.upsertInteraction(interaction),
        throwsA(isA<JobMutationFailure>()),
      );
    });
  });
}
