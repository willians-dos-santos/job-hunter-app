import 'package:flutter_test/flutter_test.dart';
import 'package:job_hunter_app/features/dashboard/domain/models/dashboard_metrics.dart';
import 'package:job_hunter_app/features/dashboard/presentation/cubit/analytics_dashboard_cubit.dart';
import 'package:job_hunter_app/features/dashboard/presentation/cubit/analytics_dashboard_state.dart';
import 'package:job_hunter_app/features/jobs/domain/models/job_item.dart';
import 'package:job_hunter_app/features/jobs/domain/models/job_status.dart';
import 'package:job_hunter_app/features/jobs/domain/repositories/job_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockJobRepository extends Mock implements IJobRepository {}

void main() {
  late MockJobRepository mockRepository;
  late AnalyticsDashboardCubit cubit;

  final testJob1 = JobItem(
    jobId: '1',
    title: 'Senior Flutter Developer',
    companyName: 'Apex Tech',
    platform: 'LinkedIn',
    jobUrl: 'https://example.com/1',
    status: JobStatus.newJob,
    isArchived: false,
  );

  final testJob2 = JobItem(
    jobId: '2',
    title: 'Lead Mobile',
    companyName: 'Apex Tech',
    platform: 'Gupy',
    jobUrl: 'https://example.com/2',
    status: JobStatus.interview,
    isArchived: false,
  );

  setUp(() {
    mockRepository = MockJobRepository();
    cubit = AnalyticsDashboardCubit(mockRepository);
  });

  tearDown(() {
    cubit.close();
  });

  group('AnalyticsDashboardCubit', () {
    test('initial state is AnalyticsDashboardInitial and exposes repository', () {
      expect(cubit.state, const AnalyticsDashboardInitial());
      expect(cubit.repository, mockRepository);
    });

    test('emits [AnalyticsDashboardLoading, AnalyticsDashboardLoaded] on successful loadMetrics', () async {
      when(() => mockRepository.getJobs(limit: any(named: 'limit')))
          .thenAnswer((_) async => [testJob1, testJob2]);

      final expectedMetrics = DashboardMetrics.fromJobs([testJob1, testJob2]);

      final expectedStates = [
        const AnalyticsDashboardLoading(),
        AnalyticsDashboardLoaded(
          metrics: expectedMetrics,
          jobs: [testJob1, testJob2],
        ),
      ];

      expectLater(cubit.stream, emitsInOrder(expectedStates));

      await cubit.loadMetrics();

      verify(() => mockRepository.getJobs(limit: 500)).called(1);
    });

    test('emits [AnalyticsDashboardLoading, AnalyticsDashboardError] when repository throws', () async {
      when(() => mockRepository.getJobs(limit: any(named: 'limit')))
          .thenThrow(Exception('Falha de conexão com Supabase'));

      final expectedStates = [
        const AnalyticsDashboardLoading(),
        predicate<AnalyticsDashboardState>(
          (state) =>
              state is AnalyticsDashboardError &&
              state.message.contains('Falha de conexão com Supabase'),
        ),
      ];

      expectLater(cubit.stream, emitsInOrder(expectedStates));

      await cubit.loadMetrics();
    });

    test('refresh() invokes loadMetrics() again', () async {
      when(() => mockRepository.getJobs(limit: any(named: 'limit')))
          .thenAnswer((_) async => [testJob1]);

      await cubit.loadMetrics();
      await cubit.refresh();

      verify(() => mockRepository.getJobs(limit: 500)).called(2);
    });
  });
}
