import 'package:flutter/foundation.dart';

import '../../../jobs/domain/models/job_item.dart';
import '../../../jobs/domain/models/job_status.dart';

/// Aggregated executive metrics computed from canonical [JobEntity] listings.
@immutable
class DashboardMetrics {
  const DashboardMetrics({
    required this.totalActiveInFunnel,
    required this.totalSubmitted,
    required this.interviewCount,
    required this.offerCount,
    required this.conversionRate,
    required this.offersReceived,
    required this.statusCounts,
    required this.totalJobs,
    required this.totalArchived,
  });

  /// Factory computing metrics from a list of [JobEntity] records from `v_user_jobs`.
  ///
  /// Governed by Spec 008:
  /// - `is_archived = true` entries are excluded from active funnel metrics.
  /// - Total Ativo no Funil: `is_archived = false` and `status != 'rejected'`.
  /// - Total de Candidaturas Submetidas: active vacancies with `status IN ('applied', 'interviewing', 'offer')`.
  /// - Taxa de Conversão para Entrevista: `(Entrevistas + Ofertas) / (Candidaturas Totais) * 100`.
  /// - Ofertas Recebidas: active vacancies with `status = 'offer'`.
  factory DashboardMetrics.fromJobs(List<JobEntity> jobs) {
    final activeJobs = jobs.where((job) => !job.isArchived).toList();

    final totalActiveInFunnel = activeJobs
        .where((job) => job.status != JobStatus.rejected)
        .length;

    final totalSubmitted = activeJobs
        .where((job) =>
            job.status == JobStatus.applied ||
            job.status == JobStatus.interview ||
            job.status == JobStatus.offer)
        .length;

    final interviewCount =
        activeJobs.where((job) => job.status == JobStatus.interview).length;

    final offerCount =
        activeJobs.where((job) => job.status == JobStatus.offer).length;

    final conversionRate = totalSubmitted > 0
        ? ((interviewCount + offerCount) / totalSubmitted) * 100.0
        : 0.0;

    final statusCounts = <JobStatus, int>{
      JobStatus.newJob:
          activeJobs.where((job) => job.status == JobStatus.newJob).length,
      JobStatus.applied:
          activeJobs.where((job) => job.status == JobStatus.applied).length,
      JobStatus.interview: interviewCount,
      JobStatus.offer: offerCount,
      JobStatus.rejected:
          activeJobs.where((job) => job.status == JobStatus.rejected).length,
    };

    final totalArchived = jobs.where((job) => job.isArchived).length;

    return DashboardMetrics(
      totalActiveInFunnel: totalActiveInFunnel,
      totalSubmitted: totalSubmitted,
      interviewCount: interviewCount,
      offerCount: offerCount,
      conversionRate: conversionRate,
      offersReceived: offerCount,
      statusCounts: statusCounts,
      totalJobs: jobs.length,
      totalArchived: totalArchived,
    );
  }

  /// Total vacancies currently active in the funnel (`!is_archived && status != rejected`).
  final int totalActiveInFunnel;

  /// Total applications submitted (`status IN ('applied', 'interviewing', 'offer')`).
  final int totalSubmitted;

  /// Number of vacancies currently in the interview stage.
  final int interviewCount;

  /// Number of received offers.
  final int offerCount;

  /// Conversion rate to interview/offer: `(Entrevistas + Ofertas) / (Total Submetidas) * 100`.
  final double conversionRate;

  /// Confirmed job offers received (`status = 'offer'`).
  final int offersReceived;

  /// Breakdown of active vacancy counts keyed by [JobStatus].
  final Map<JobStatus, int> statusCounts;

  /// Total count of all job records retrieved (including archived).
  final int totalJobs;

  /// Count of archived jobs.
  final int totalArchived;

  /// Formatted conversion rate string (e.g. `25.0%`).
  String get formattedConversionRate => '${conversionRate.toStringAsFixed(1)}%';

  /// Returns count for a given status.
  int countForStatus(JobStatus status) => statusCounts[status] ?? 0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DashboardMetrics &&
        other.totalActiveInFunnel == totalActiveInFunnel &&
        other.totalSubmitted == totalSubmitted &&
        other.interviewCount == interviewCount &&
        other.offerCount == offerCount &&
        (other.conversionRate - conversionRate).abs() < 0.0001 &&
        other.offersReceived == offersReceived &&
        mapEquals(other.statusCounts, statusCounts) &&
        other.totalJobs == totalJobs &&
        other.totalArchived == totalArchived;
  }

  @override
  int get hashCode => Object.hash(
        totalActiveInFunnel,
        totalSubmitted,
        interviewCount,
        offerCount,
        conversionRate,
        offersReceived,
        Object.hashAll(statusCounts.keys),
        Object.hashAll(statusCounts.values),
        totalJobs,
        totalArchived,
      );

  @override
  String toString() {
    return 'DashboardMetrics(activeInFunnel: $totalActiveInFunnel, submitted: $totalSubmitted, '
        'conversionRate: $formattedConversionRate, offers: $offersReceived)';
  }
}
