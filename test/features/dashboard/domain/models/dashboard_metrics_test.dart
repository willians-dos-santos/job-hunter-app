import 'package:flutter_test/flutter_test.dart';
import 'package:job_hunter_app/features/dashboard/domain/models/dashboard_metrics.dart';
import 'package:job_hunter_app/features/jobs/domain/models/job_item.dart';
import 'package:job_hunter_app/features/jobs/domain/models/job_status.dart';

void main() {
  group('DashboardMetrics', () {
    final newJob1 = JobItem(
      jobId: '1',
      title: 'Dev Flutter',
      companyName: 'Company A',
      platform: 'LinkedIn',
      jobUrl: 'https://example.com/1',
      status: JobStatus.newJob,
      isArchived: false,
    );

    final appliedJob = JobItem(
      jobId: '2',
      title: 'Senior Dev',
      companyName: 'Company B',
      platform: 'Gupy',
      jobUrl: 'https://example.com/2',
      status: JobStatus.applied,
      isArchived: false,
    );

    final interviewJob = JobItem(
      jobId: '3',
      title: 'Lead Mobile',
      companyName: 'Company C',
      platform: 'Catho',
      jobUrl: 'https://example.com/3',
      status: JobStatus.interview,
      isArchived: false,
    );

    final offerJob = JobItem(
      jobId: '4',
      title: 'Staff Engineer',
      companyName: 'Company D',
      platform: 'LinkedIn',
      jobUrl: 'https://example.com/4',
      status: JobStatus.offer,
      isArchived: false,
    );

    final rejectedJob = JobItem(
      jobId: '5',
      title: 'Architect',
      companyName: 'Company E',
      platform: 'LinkedIn',
      jobUrl: 'https://example.com/5',
      status: JobStatus.rejected,
      isArchived: false,
    );

    final archivedJob = JobItem(
      jobId: '6',
      title: 'Discarded Dev',
      companyName: 'Company F',
      platform: 'LinkedIn',
      jobUrl: 'https://example.com/6',
      status: JobStatus.applied,
      isArchived: true,
    );

    test('computes KPI metrics accurately according to Spec 008 contract', () {
      final jobs = [
        newJob1,
        appliedJob,
        interviewJob,
        offerJob,
        rejectedJob,
        archivedJob,
      ];

      final metrics = DashboardMetrics.fromJobs(jobs);

      // Total Ativo no Funil: is_archived = false e status != 'rejected'
      // Ativas não rejeitadas: newJob1, appliedJob, interviewJob, offerJob = 4
      expect(metrics.totalActiveInFunnel, 4);

      // Total de Candidaturas Submetidas: status IN ('applied', 'interviewing', 'offer') e is_archived = false
      // appliedJob, interviewJob, offerJob = 3
      expect(metrics.totalSubmitted, 3);

      // Entrevistas = 1, Ofertas = 1
      expect(metrics.interviewCount, 1);
      expect(metrics.offerCount, 1);
      expect(metrics.offersReceived, 1);

      // Taxa de Conversão: (1 + 1) / 3 * 100 = 66.666...%
      expect(metrics.conversionRate, closeTo(66.666, 0.01));
      expect(metrics.formattedConversionRate, '66.7%');

      // Status distribution
      expect(metrics.countForStatus(JobStatus.newJob), 1);
      expect(metrics.countForStatus(JobStatus.applied), 1);
      expect(metrics.countForStatus(JobStatus.interview), 1);
      expect(metrics.countForStatus(JobStatus.offer), 1);
      expect(metrics.countForStatus(JobStatus.rejected), 1);

      // Historical totals
      expect(metrics.totalJobs, 6);
      expect(metrics.totalArchived, 1);
    });

    test('handles empty job list gracefully with 0 conversion rate', () {
      final metrics = DashboardMetrics.fromJobs([]);

      expect(metrics.totalActiveInFunnel, 0);
      expect(metrics.totalSubmitted, 0);
      expect(metrics.interviewCount, 0);
      expect(metrics.offerCount, 0);
      expect(metrics.offersReceived, 0);
      expect(metrics.conversionRate, 0.0);
      expect(metrics.formattedConversionRate, '0.0%');
      expect(metrics.totalJobs, 0);
      expect(metrics.totalArchived, 0);
    });

    test('handles zero submitted jobs avoiding division by zero', () {
      final jobs = [newJob1, rejectedJob];
      final metrics = DashboardMetrics.fromJobs(jobs);

      expect(metrics.totalActiveInFunnel, 1);
      expect(metrics.totalSubmitted, 0);
      expect(metrics.conversionRate, 0.0);
      expect(metrics.formattedConversionRate, '0.0%');
    });

    test('excludes archived vacancies from active funnel even if status is offer', () {
      final archivedOffer = JobItem(
        jobId: '7',
        title: 'Archived Offer',
        companyName: 'Company G',
        platform: 'LinkedIn',
        jobUrl: 'https://example.com/7',
        status: JobStatus.offer,
        isArchived: true,
      );

      final metrics = DashboardMetrics.fromJobs([archivedOffer]);

      expect(metrics.totalActiveInFunnel, 0);
      expect(metrics.totalSubmitted, 0);
      expect(metrics.offerCount, 0);
      expect(metrics.offersReceived, 0);
      expect(metrics.totalArchived, 1);
      expect(metrics.totalJobs, 1);
    });

    test('supports value equality and toString', () {
      final m1 = DashboardMetrics.fromJobs([newJob1, appliedJob]);
      final m2 = DashboardMetrics.fromJobs([newJob1, appliedJob]);

      expect(m1, equals(m2));
      expect(m1.hashCode, equals(m2.hashCode));
      expect(m1.toString(), contains('activeInFunnel'));
    });
  });
}
