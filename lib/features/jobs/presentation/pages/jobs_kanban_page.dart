import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/job_status.dart';
import '../cubit/jobs_cubit.dart';
import '../cubit/jobs_state.dart';
import '../widgets/kanban_column.dart';
import '../widgets/kanban_error_view.dart';
import '../widgets/kanban_loading_skeleton.dart';

/// Full Kanban board screen displaying the application funnel across 5 stages.
class JobsKanbanPage extends StatefulWidget {
  const JobsKanbanPage({super.key, this.cubit});

  final JobsCubit? cubit;

  @override
  State<JobsKanbanPage> createState() => _JobsKanbanPageState();
}

class _JobsKanbanPageState extends State<JobsKanbanPage> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  JobsCubit _resolveCubit(BuildContext context) {
    if (widget.cubit != null) return widget.cubit!;
    return context.read<JobsCubit>();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = _resolveCubit(context);

    return Scaffold(
      backgroundColor: AppColors.slate900,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryIndigo.withAlpha(45),
                borderRadius: BorderRadius.circular(6),
                border:
                    Border.all(color: AppColors.primaryIndigo.withAlpha(120)),
              ),
              child: Text(
                'KANBAN',
                style: AppTypography.monoTag(color: AppColors.terminalCyan),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Quadro de Vagas',
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Atualizar vagas',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              cubit.loadJobs();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocConsumer<JobsCubit, JobsState>(
        bloc: cubit,
        listener: (context, state) {
          if (state is JobsLoaded && state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppColors.kanbanRejected,
                behavior: SnackBarBehavior.floating,
                content: Text(
                  state.errorMessage!,
                  style: const TextStyle(color: Colors.white),
                ),
                action: SnackBarAction(
                  label: 'OK',
                  textColor: Colors.white,
                  onPressed: () => cubit.clearErrorMessage(),
                ),
              ),
            );
            cubit.clearErrorMessage();
          }
        },
        builder: (context, state) {
          if (state is JobsInitial || state is JobsLoading) {
            return const KanbanLoadingSkeleton();
          }

          if (state is JobsError) {
            return KanbanErrorView(
              message: state.message,
              onRetry: () => cubit.loadJobs(),
            );
          }

          if (state is JobsLoaded) {
            return Column(
              children: [
                // Search and Filters Bar
                _buildSearchBar(context, cubit, state),

                // Kanban 5 Columns
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      const columnCount = 5;
                      final isFluid = constraints.maxWidth >= 1400;
                      final columnWidth = isFluid
                          ? (constraints.maxWidth - 32 - (4 * 16)) / columnCount
                          : 300.0;

                      final availableHeight = constraints.maxHeight - 16;

                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: SizedBox(
                          height: availableHeight > 0
                              ? availableHeight
                              : constraints.maxHeight,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (int i = 0; i < JobStatus.values.length; i++)
                                Container(
                                  width: columnWidth,
                                  margin: EdgeInsets.only(
                                    right: i < JobStatus.values.length - 1
                                        ? 16
                                        : 0,
                                  ),
                                  child: KanbanColumn(
                                    key: ValueKey(
                                        'kanban_col_${JobStatus.values[i].value}'),
                                    status: JobStatus.values[i],
                                    jobs: state
                                        .jobsByStatus(JobStatus.values[i]),
                                    onMoveJobStatus: (job, newStatus) {
                                      cubit.moveJobStatus(
                                        jobId: job.jobId,
                                        newStatus: newStatus.value,
                                      );
                                    },
                                    onArchiveJob: (job) {
                                      cubit.archiveJob(job.jobId);
                                    },
                                    onJobDropped: (job, targetStatus) {
                                      cubit.moveJobStatus(
                                        jobId: job.jobId,
                                        newStatus: targetStatus.value,
                                      );
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSearchBar(
      BuildContext context, JobsCubit cubit, JobsLoaded state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.slate900,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) => cubit.filterJobs(value),
              style: const TextStyle(
                color: AppColors.textWhite,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'Buscar por cargo, empresa, localização...',
                hintStyle: const TextStyle(
                  color: AppColors.textSlate500,
                  fontSize: 13,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.textSlate400,
                  size: 20,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear_rounded,
                          color: AppColors.textSlate400,
                          size: 18,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          cubit.filterJobs('');
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.slate800,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.slate700),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.slate700),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: AppColors.primaryIndigo,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Total jobs counter badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.slate800,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.slate700),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.view_kanban_rounded,
                  size: 16,
                  color: AppColors.terminalCyan,
                ),
                const SizedBox(width: 6),
                Text(
                  '${state.jobs.length} vagas',
                  style: AppTypography.mono(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textWhite,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
