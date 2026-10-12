import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/job_modality.dart';
import '../../domain/models/job_status.dart';
import '../cubit/jobs_cubit.dart';
import '../cubit/jobs_state.dart';
import '../widgets/job_details_modal.dart';
import '../widgets/kanban_column.dart';
import '../widgets/kanban_error_view.dart';
import '../widgets/kanban_loading_skeleton.dart';
import 'archived_jobs_screen.dart';

/// Full Kanban board screen displaying the application funnel across 5 stages,
/// with real-time debounced search and quick modality filter chips.
class JobsKanbanPage extends StatefulWidget {
  const JobsKanbanPage({
    super.key,
    this.cubit,
    this.debounceDuration = const Duration(milliseconds: 400),
  });

  final JobsCubit? cubit;
  final Duration debounceDuration;

  @override
  State<JobsKanbanPage> createState() => _JobsKanbanPageState();
}

class _JobsKanbanPageState extends State<JobsKanbanPage> {
  late final TextEditingController _searchController;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  JobsCubit _resolveCubit(BuildContext context) {
    if (widget.cubit != null) return widget.cubit!;
    return context.read<JobsCubit>();
  }

  void _onSearchChanged(String value, JobsCubit cubit) {
    _debounceTimer?.cancel();
    if (widget.debounceDuration == Duration.zero) {
      cubit.filterJobs(value);
    } else {
      _debounceTimer = Timer(widget.debounceDuration, () {
        if (mounted) {
          cubit.filterJobs(value);
        }
      });
    }
    setState(() {});
  }

  void _onClearSearch(JobsCubit cubit) {
    _debounceTimer?.cancel();
    _searchController.clear();
    cubit.filterJobs('');
    setState(() {});
  }

  void _onResetAllFilters(JobsCubit cubit) {
    _debounceTimer?.cancel();
    _searchController.clear();
    cubit.resetFilters();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final cubit = _resolveCubit(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
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
            tooltip: 'Vagas arquivadas',
            icon: const Icon(Icons.archive_outlined),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ArchivedJobsScreen(
                    repository: cubit.repository,
                  ),
                ),
              );
              cubit.loadJobs();
            },
          ),
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
          if (state is JobsLoaded) {
            if (state.errorMessage != null) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
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
            } else if (state.successMessage != null) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.slate800,
                  behavior: SnackBarBehavior.floating,
                  content: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        color: AppColors.terminalCyan,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          state.successMessage!,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  duration: const Duration(seconds: 3),
                ),
              );
              cubit.clearSuccessMessage();
            }
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
            final isFilteredEmpty = state.jobs.isEmpty && state.hasActiveFilter;

            return Column(
              children: [
                // Search and Filters Bar
                _buildSearchBar(context, cubit, state),

                // Kanban 5 Columns or Empty Filtered State
                Expanded(
                  child: isFilteredEmpty
                      ? _buildEmptyFilteredState(context, cubit)
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            const columnCount = 5;
                            final isFluid = constraints.maxWidth >= 1400;
                            final columnWidth = isFluid
                                ? (constraints.maxWidth - 32 - (4 * 16)) /
                                    columnCount
                                : 300.0;

                            final availableHeight = constraints.maxHeight - 16;
                            const minColumnHeight = 220.0;
                            final effectiveHeight =
                                availableHeight > minColumnHeight
                                    ? availableHeight
                                    : minColumnHeight;

                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              physics: const BouncingScrollPhysics(
                                parent: AlwaysScrollableScrollPhysics(),
                              ),
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: SizedBox(
                                height: effectiveHeight,
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    for (int i = 0;
                                        i < JobStatus.values.length;
                                        i++)
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
                                          jobs: state.jobsByStatus(
                                              JobStatus.values[i]),
                                          onJobTap: (job) {
                                            showJobDetailsModal(
                                              context,
                                              job: job,
                                              cubit: cubit,
                                            );
                                          },
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => _onSearchChanged(value, cubit),
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
                            onPressed: () => _onClearSearch(cubit),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.slate800,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.slate700),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
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
          const SizedBox(height: 10),
          _buildModalityChips(context, cubit, state),
        ],
      ),
    );
  }

  Widget _buildModalityChips(
      BuildContext context, JobsCubit cubit, JobsLoaded state) {
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const BouncingScrollPhysics(),
        children: [
          for (final filter in JobModalityFilter.values) ...[
            _ModalityFilterChip(
              key: ValueKey('chip_modality_${filter.name}'),
              filter: filter,
              isSelected: state.selectedModality == filter,
              onSelected: () => cubit.setModalityFilter(filter),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyFilteredState(BuildContext context, JobsCubit cubit) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;

        return SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: availableHeight > 48 ? availableHeight - 48 : 0,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.slate800,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.slate700),
                    ),
                    child: const Icon(
                      Icons.search_off_rounded,
                      size: 44,
                      color: AppColors.textSlate400,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhuma vaga encontrada',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.textWhite,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Text(
                      'Nenhum resultado corresponde à sua pesquisa ou filtro atual.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSlate400,
                          ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    key: const Key('reset_filters_button'),
                    onPressed: () => _onResetAllFilters(cubit),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Redefinir filtros'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryIndigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ModalityFilterChip extends StatelessWidget {
  const _ModalityFilterChip({
    super.key,
    required this.filter,
    required this.isSelected,
    required this.onSelected,
  });

  final JobModalityFilter filter;
  final bool isSelected;
  final VoidCallback onSelected;

  IconData _iconFor(JobModalityFilter filter) {
    switch (filter) {
      case JobModalityFilter.all:
        return Icons.apps_rounded;
      case JobModalityFilter.remote:
        return Icons.wifi_rounded;
      case JobModalityFilter.hybrid:
        return Icons.sync_alt_rounded;
      case JobModalityFilter.onSite:
        return Icons.business_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isSelected
        ? AppColors.primaryIndigo.withAlpha(55)
        : AppColors.slate800;
    final borderColor =
        isSelected ? AppColors.primaryIndigo : AppColors.slate700;
    final contentColor =
        isSelected ? AppColors.terminalCyan : AppColors.textSlate400;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onSelected,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: borderColor,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _iconFor(filter),
                size: 14,
                color: contentColor,
              ),
              const SizedBox(width: 6),
              Text(
                filter.label,
                style: AppTypography.monoTag(
                  color:
                      isSelected ? AppColors.textWhite : AppColors.textSlate400,
                ).copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
