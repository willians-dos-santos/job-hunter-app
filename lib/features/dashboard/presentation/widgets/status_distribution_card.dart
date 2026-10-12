import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/kanban_status_colors.dart';
import '../../../jobs/domain/models/job_status.dart';
import '../../domain/models/dashboard_metrics.dart';

/// Card presenting horizontal comparison bars detailing the count and percentage per funnel status.
class StatusDistributionCard extends StatelessWidget {
  const StatusDistributionCard({
    super.key,
    required this.metrics,
  });

  final DashboardMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final colors = context.kanbanColors;

    // Spec 008 statuses: 'new', 'applied', 'interviewing', 'offer', 'rejected'
    final stages = [
      _StageData(
        status: JobStatus.newJob,
        rawName: 'new',
        label: 'Novas Vagas',
        color: colors.newJob,
        count: metrics.countForStatus(JobStatus.newJob),
      ),
      _StageData(
        status: JobStatus.applied,
        rawName: 'applied',
        label: 'Candidatadas',
        color: colors.applied,
        count: metrics.countForStatus(JobStatus.applied),
      ),
      _StageData(
        status: JobStatus.interview,
        rawName: 'interviewing',
        label: 'Em Entrevista',
        color: colors.interview,
        count: metrics.countForStatus(JobStatus.interview),
      ),
      _StageData(
        status: JobStatus.offer,
        rawName: 'offer',
        label: 'Ofertas / Propostas',
        color: colors.offer,
        count: metrics.countForStatus(JobStatus.offer),
      ),
      _StageData(
        status: JobStatus.rejected,
        rawName: 'rejected',
        label: 'Rejeitadas',
        color: colors.rejected,
        count: metrics.countForStatus(JobStatus.rejected),
      ),
    ];

    // Compute maximum count to scale horizontal bars proportionally
    final maxCount = stages.fold<int>(
      0,
      (prev, stage) => stage.count > prev ? stage.count : prev,
    );
    final totalFunnelCount = stages.fold<int>(
      0,
      (prev, stage) => prev + stage.count,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.slate800,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slate700),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Distribuição por Status',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textWhite,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Detalhamento comparativo das etapas do funil',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSlate400,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.slate900,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.slate700),
                ),
                child: Text(
                  '$totalFunnelCount VAGAS',
                  style: AppTypography.monoTag(
                    color: AppColors.terminalCyan,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: AppColors.slate700, height: 1),
          const SizedBox(height: 16),
          ...stages.map((stage) {
            final percentage = totalFunnelCount > 0
                ? (stage.count / totalFunnelCount * 100)
                : 0.0;
            final progressFactor =
                maxCount > 0 ? (stage.count / maxCount) : 0.0;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: stage.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Row(
                          children: [
                            Text(
                              stage.label,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textWhite,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "('${stage.rawName}')",
                              style: AppTypography.monoTag(
                                color: AppColors.textSlate500,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${percentage.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSlate400,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        constraints: const BoxConstraints(minWidth: 32),
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${stage.count}',
                          style: AppTypography.mono(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textWhite,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Barra de progresso horizontal personalizada
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Stack(
                      children: [
                        Container(
                          height: 8,
                          width: double.infinity,
                          color: AppColors.slate700,
                        ),
                        FractionallySizedBox(
                          widthFactor: progressFactor.clamp(0.0, 1.0),
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: stage.color,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _StageData {
  const _StageData({
    required this.status,
    required this.rawName,
    required this.label,
    required this.color,
    required this.count,
  });

  final JobStatus status;
  final String rawName;
  final String label;
  final Color color;
  final int count;
}
