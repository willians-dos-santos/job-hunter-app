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
    this.onJobTap,
    this.onMoveJobStatus,
    this.onArchiveJob,
    this.onOpenJobUrl,
    this.onJobDropped,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.onLoadMore,
    this.paginationError,
  });

  final JobStatus status;
  final List<JobItem> jobs;
  final void Function(JobItem job)? onJobTap;
  final void Function(JobItem job, JobStatus newStatus)? onMoveJobStatus;
  final void Function(JobItem job)? onArchiveJob;
  final void Function(JobItem job)? onOpenJobUrl;
  final void Function(JobItem job, JobStatus targetStatus)? onJobDropped;
  final bool hasMore;
  final bool isLoadingMore;
  final VoidCallback? onLoadMore;
  final String? paginationError;

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
                    ? (isLoadingMore
                        ? _buildEmptyLoadingState(context, statusColor)
                        : (paginationError != null
                            ? _buildEmptyErrorState(context, statusColor)
                            : _buildEmptyState(context, statusColor)))
                    : NotificationListener<ScrollNotification>(
                        onNotification: (ScrollNotification scrollInfo) {
                          if (hasMore &&
                              !isLoadingMore &&
                              paginationError == null &&
                              onLoadMore != null) {
                            if (scrollInfo.metrics.pixels >=
                                scrollInfo.metrics.maxScrollExtent - 60) {
                              onLoadMore!();
                            }
                          }
                          return false;
                        },
                        child: ListView.separated(
                          padding: const EdgeInsets.all(12),
                          physics: const AlwaysScrollableScrollPhysics(),
                          primary: false,
                          itemCount: jobs.length +
                              (hasMore ||
                                      isLoadingMore ||
                                      paginationError != null
                                  ? 1
                                  : 0),
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            if (index < jobs.length) {
                              final job = jobs[index];
                              return JobCard(
                                key: ValueKey('job_card_${job.jobId}'),
                                job: job,
                                onTap: () => onJobTap?.call(job),
                                onMoveStatus: (newStatus) =>
                                    onMoveJobStatus?.call(job, newStatus),
                                onArchive: () => onArchiveJob?.call(job),
                                onOpenUrl: () => onOpenJobUrl?.call(job),
                              );
                            }
                            return _buildPaginationFooter(context, statusColor);
                          },
                        ),
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
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                const Icon(
                  Icons.inbox_outlined,
                  size: 26,
                  color: AppColors.textSlate500,
                ),
                const SizedBox(height: 6),
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
      ),
    );
  }

  Widget _buildEmptyLoadingState(BuildContext context, Color statusColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Carregando vagas...',
              style: AppTypography.mono(
                fontSize: 12,
                color: AppColors.textSlate400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyErrorState(BuildContext context, Color statusColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.slate800,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.kanbanRejected.withAlpha(120)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                paginationError ?? 'Erro ao carregar vagas',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.kanbanRejected,
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                key: const ValueKey('kanban_column_empty_retry_button'),
                onPressed: onLoadMore,
                icon: const Icon(
                  Icons.refresh_rounded,
                  size: 14,
                  color: AppColors.terminalCyan,
                ),
                label: Text(
                  'Tentar novamente',
                  style: AppTypography.monoTag(color: AppColors.terminalCyan),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.slate700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaginationFooter(BuildContext context, Color statusColor) {
    if (isLoadingMore) {
      return Container(
        key: const ValueKey('kanban_column_loading_more'),
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Carregando mais vagas...',
                overflow: TextOverflow.ellipsis,
                style: AppTypography.mono(
                  fontSize: 12,
                  color: AppColors.textSlate400,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (paginationError != null) {
      return Container(
        key: const ValueKey('kanban_column_pagination_error'),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.slate800,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.kanbanRejected.withAlpha(100)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              paginationError!,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.kanbanRejected,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            InkWell(
              key: const ValueKey('kanban_column_retry_button'),
              onTap: onLoadMore,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.refresh_rounded,
                      size: 14,
                      color: AppColors.terminalCyan,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Tentar novamente',
                      style:
                          AppTypography.monoTag(color: AppColors.terminalCyan),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (hasMore) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        alignment: Alignment.center,
        child: TextButton.icon(
          key: const ValueKey('kanban_column_load_more_button'),
          onPressed: onLoadMore,
          icon: const Icon(
            Icons.expand_more_rounded,
            size: 16,
            color: AppColors.terminalCyan,
          ),
          label: Text(
            'Carregar mais vagas',
            style: AppTypography.monoTag(color: AppColors.textWhite),
          ),
          style: TextButton.styleFrom(
            backgroundColor: AppColors.slate800,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: AppColors.slate700),
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
