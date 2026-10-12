import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/kanban_status_colors.dart';
import '../../data/repositories/job_repository_impl.dart';
import '../../domain/models/job_item.dart';
import '../../domain/repositories/job_repository.dart';
import '../cubit/archived_jobs_cubit.dart';
import '../cubit/archived_jobs_state.dart';
import '../widgets/job_details_modal.dart';

/// Screen displaying archived job vacancies with options to audit, view details,
/// and restore them back to the active Kanban funnel.
class ArchivedJobsScreen extends StatefulWidget {
  const ArchivedJobsScreen({
    super.key,
    this.cubit,
    this.repository,
  });

  final ArchivedJobsCubit? cubit;
  final IJobRepository? repository;

  @override
  State<ArchivedJobsScreen> createState() => _ArchivedJobsScreenState();
}

class _ArchivedJobsScreenState extends State<ArchivedJobsScreen> {
  late final ArchivedJobsCubit _cubit;
  bool _ownsCubit = false;

  @override
  void initState() {
    super.initState();
    if (widget.cubit != null) {
      _cubit = widget.cubit!;
    } else {
      _cubit = ArchivedJobsCubit(widget.repository ?? JobRepository());
      _ownsCubit = true;
      _cubit.loadArchivedJobs();
    }
  }

  @override
  void dispose() {
    if (_ownsCubit) {
      _cubit.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.slate900,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Voltar',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
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
                'ARQUIVO',
                style: AppTypography.monoTag(color: AppColors.terminalCyan),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Vagas Arquivadas',
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
            tooltip: 'Atualizar vagas arquivadas',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _cubit.loadArchivedJobs(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: BlocConsumer<ArchivedJobsCubit, ArchivedJobsState>(
          bloc: _cubit,
        listener: (context, state) {
          if (state is ArchivedJobsLoaded) {
            if (state.errorMessage != null) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: AppColors.kanbanRejected,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              _cubit.clearErrorMessage();
            } else if (state.successMessage != null) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.successMessage!),
                  backgroundColor: AppColors.kanbanOffer,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              _cubit.clearSuccessMessage();
            }
          }
        },
        builder: (context, state) {
          if (state is ArchivedJobsLoading || state is ArchivedJobsInitial) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.terminalCyan),
              ),
            );
          }

          if (state is ArchivedJobsError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.kanbanRejected,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSlate300,
                          ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () => _cubit.loadArchivedJobs(),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Tentar novamente'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryIndigo,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is ArchivedJobsLoaded) {
            if (state.jobs.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.slate800,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.slate700),
                        ),
                        child: const Icon(
                          Icons.inventory_2_outlined,
                          size: 48,
                          color: AppColors.textSlate400,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Nenhuma vaga arquivada',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppColors.textWhite,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Vagas descartadas no quadro aparecerão aqui para auditoria e recuperação.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSlate400,
                            ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.jobs.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final job = state.jobs[index];
                return _ArchivedJobCard(
                  job: job,
                  onTap: () => showJobDetailsModal(context, job: job),
                  onRestore: () => _cubit.restoreJob(job.jobId),
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    ),
  );
  }
}

/// Backwards-compatible alias for [ArchivedJobsScreen].
typedef ArchivedJobsPage = ArchivedJobsScreen;

/// Individual card for an archived job item.
class _ArchivedJobCard extends StatelessWidget {
  const _ArchivedJobCard({
    required this.job,
    required this.onTap,
    required this.onRestore,
  });

  final JobItem job;
  final VoidCallback onTap;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final statusColor = context.kanbanColors.colorFor(job.status);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.slate800,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slate700),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: AppColors.textWhite,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            job.companyName,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.textSlate400,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.unarchive_rounded, size: 16),
                      label: const Text('Restaurar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.terminalCyan,
                        side: const BorderSide(
                          color: AppColors.terminalCyan,
                          width: 1.2,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: onRestore,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withAlpha(35),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: statusColor.withAlpha(120)),
                      ),
                      child: Text(
                        job.status.label,
                        style: AppTypography.monoTag(color: statusColor),
                      ),
                    ),
                    // Platform Badge
                    if (job.platform.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.slate900,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.slate700),
                        ),
                        child: Text(
                          job.platform,
                          style: AppTypography.inter(
                            fontSize: 11,
                            color: AppColors.textSlate400,
                          ),
                        ),
                      ),
                    // Location / Modality
                    if (job.location != null && job.location!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.slate900,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.slate700),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.place_outlined,
                              size: 12,
                              color: AppColors.textSlate400,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              job.location!,
                              style: AppTypography.inter(
                                fontSize: 11,
                                color: AppColors.textSlate400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Salary
                    if (job.salaryText != null && job.salaryText!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.slate900,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.slate700),
                        ),
                        child: Text(
                          job.salaryText!,
                          style: AppTypography.mono(
                            fontSize: 11,
                            color: AppColors.kanbanOffer,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
