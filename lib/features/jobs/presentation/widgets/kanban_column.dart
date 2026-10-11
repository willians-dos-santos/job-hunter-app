import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/kanban_status_colors.dart';
import '../../domain/models/job_item.dart';
import '../../domain/models/job_status.dart';
import 'job_card.dart';

/// Single Kanban funnel column rendering the header indicator, counter,
/// scrollable job cards, and empty state.
class KanbanColumn extends StatelessWidget {
  const KanbanColumn({
    super.key,
    required this.status,
    required this.jobs,
    this.onMoveJobStatus,
    this.onArchiveJob,
    this.onOpenJobUrl,
    this.onJobDropped,
  });

  final JobStatus status;
  final List<JobItem> jobs;
  final void Function(JobItem job, JobStatus newStatus)? onMoveJobStatus;
  final void Function(JobItem job)? onArchiveJob;
  final void Function(JobItem job)? onOpenJobUrl;
  final void Function(JobItem job, JobStatus targetStatus)? onJobDropped;

  @override
  Widget build(BuildContext context) {
    final statusColor = context.kanbanColors.colorFor(status);

    return DragTarget<JobItem>(
      hitTestBehavior: HitTestBehavior.translucent,
      onWillAcceptWithDetails: (details) => details.data.status != status,
      onAcceptWithDetails: (details) {
        if (onJobDropped != null) {
          onJobDropped!(details.data, status);
        } else {
          onMoveJobStatus?.call(details.data, status);
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: isHovered
                ? statusColor.withAlpha(20)
                : AppColors.slate900,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isHovered
                  ? statusColor
                  : AppColors.slate700.withAlpha(120),
              width: isHovered ? 2.0 : 1.0,
            ),
            boxShadow: isHovered
                ? [
                    BoxShadow(
                      color: statusColor.withAlpha(70),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Column Header (fixo no topo)
              _buildHeader(context, statusColor, isHovered: isHovered),

              Divider(
                height: 1,
                thickness: 1,
                color: isHovered
                    ? statusColor.withAlpha(100)
                    : AppColors.slate700,
              ),

              // Scrollable Card List
              Expanded(
                child: jobs.isEmpty
                    ? _buildEmptyState(context, statusColor)
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        physics: const AlwaysScrollableScrollPhysics(),
                        primary: false,
                        itemCount: jobs.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final job = jobs[index];
                          return JobCard(
                            key: ValueKey('job_card_${job.jobId}'),
                            job: job,
                            onMoveStatus: (newStatus) =>
                                onMoveJobStatus?.call(job, newStatus),
                            onArchive: () => onArchiveJob?.call(job),
                            onOpenUrl: () => onOpenJobUrl?.call(job),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    Color statusColor, {
    bool isHovered = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isHovered ? statusColor.withAlpha(35) : AppColors.slate850,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(14),
          topRight: Radius.circular(14),
        ),
      ),
      child: Row(
        children: [
          // Indicator dot
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: statusColor.withAlpha(120),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Title
          Expanded(
            child: Text(
              status.label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.textWhite,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
            ),
          ),

          // Card count badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isHovered
                  ? statusColor.withAlpha(50)
                  : AppColors.slate800,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isHovered
                    ? statusColor.withAlpha(160)
                    : AppColors.slate700,
              ),
            ),
            child: Text(
              '${jobs.length}',
              style: AppTypography.mono(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, Color statusColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          decoration: BoxDecoration(
            color: AppColors.slate850.withAlpha(100),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.slate700.withAlpha(140),
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 28,
                color: AppColors.textSlate500,
              ),
              const SizedBox(height: 8),
              Text(
                'Nenhuma vaga nesta etapa',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSlate500,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
