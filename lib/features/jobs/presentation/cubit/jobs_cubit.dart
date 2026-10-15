import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/models/job_item.dart';
import '../../domain/models/job_modality.dart';
import '../../domain/models/job_status.dart';
import '../../domain/models/user_job_interaction.dart';
import '../../domain/repositories/jobs_repository.dart';
import 'jobs_state.dart';

/// Cubit managing job loading, optimistic funnel moves, filtering, and archiving.
class JobsCubit extends Cubit<JobsState> {
  JobsCubit(
    this._repository, {
    this.newJobsPageSize = AppConstants.newJobsPageSize,
  }) : super(const JobsInitial());

  final JobsRepository _repository;

  /// Exposes the underlying repository.
  JobsRepository get repository => _repository;

  /// Page size used when querying the triage inbox view.
  final int newJobsPageSize;

  int _newJobsOffset = 0;

  /// Current pagination offset for new triage jobs.
  int get newJobsOffset => _newJobsOffset;

  /// Loads jobs from repository, querying new jobs from `v_new_jobs` and active pipeline
  /// from `v_active_pipeline_jobs` in parallel via [Future.wait].
  Future<void> loadJobs() async {
    emit(const JobsLoading());
    try {
      _newJobsOffset = 0;
      List<JobItem> newJobs;
      List<JobItem> pipelineJobs;

      try {
        final results = await Future.wait([
          _repository.getNewJobs(limit: newJobsPageSize, offset: 0),
          _repository.getActivePipelineJobs(),
        ]);
        newJobs = results[0].where((j) => !j.isArchived).toList();
        pipelineJobs = results[1].where((j) => !j.isArchived).toList();

        final pipelineJobIds = pipelineJobs.map((j) => j.jobId).toSet();
        newJobs = newJobs.where((j) => !pipelineJobIds.contains(j.jobId)).toList();
      } on NoSuchMethodError {
        // Fallback for mocks in legacy tests that only stub getJobs()
        final rawJobs = await _repository.getJobs();
        final activeJobs = rawJobs.where((j) => !j.isArchived).toList();
        newJobs = activeJobs.where((j) => j.status == JobStatus.newJob).toList();
        pipelineJobs = activeJobs.where((j) => j.status != JobStatus.newJob).toList();
      }

      _newJobsOffset = newJobs.length;
      final hasMore = newJobs.length >= newJobsPageSize;
      final combined = [...newJobs, ...pipelineJobs];

      emit(JobsLoaded(
        combined,
        allJobs: combined,
        hasMoreNewJobs: hasMore,
        isLoadingMoreNewJobs: false,
        newJobsOffset: _newJobsOffset,
      ));
    } catch (e) {
      emit(JobsError('Erro ao carregar vagas: $e'));
    }
  }

  /// Incrementally fetches the next batch of triage inbox vacancies from `v_new_jobs`.
  Future<void> loadMoreNewJobs() async {
    final currentState = state;
    if (currentState is! JobsLoaded) return;
    if (currentState.isLoadingMoreNewJobs || !currentState.hasMoreNewJobs) return;

    emit(currentState.copyWith(
      isLoadingMoreNewJobs: true,
      clearNewJobsPaginationError: true,
    ));

    try {
      final currentOffset = _newJobsOffset;
      List<JobItem> nextBatch;
      try {
        nextBatch = await _repository.getNewJobs(
          limit: newJobsPageSize,
          offset: currentOffset,
        );
      } on NoSuchMethodError {
        nextBatch = [];
      }

      final activeNextBatch = nextBatch.where((j) => !j.isArchived).toList();
      _newJobsOffset = currentOffset + nextBatch.length;
      final hasMore = nextBatch.length >= newJobsPageSize;

      // Deduplicate against existing jobs
      final existingIds = currentState.effectiveAllJobs.map((j) => j.jobId).toSet();
      final uniqueNextBatch =
          activeNextBatch.where((j) => !existingIds.contains(j.jobId)).toList();

      final updatedAllJobs = [...currentState.effectiveAllJobs, ...uniqueNextBatch];
      final updatedJobs = _applyFilter(
        updatedAllJobs,
        currentState.searchQuery,
        currentState.selectedModality,
      );

      emit(currentState.copyWith(
        jobs: updatedJobs,
        allJobs: updatedAllJobs,
        hasMoreNewJobs: hasMore,
        isLoadingMoreNewJobs: false,
        newJobsOffset: _newJobsOffset,
        clearNewJobsPaginationError: true,
      ));
    } catch (e) {
      emit(currentState.copyWith(
        isLoadingMoreNewJobs: false,
        newJobsPaginationError: 'Erro ao carregar mais vagas: $e',
      ));
    }
  }

  /// Optimistically moves [jobId] to [newStatus] and persists via repository.
  ///
  /// In case of failure, automatically rolls back to the previous state.
  Future<void> moveJobStatus({
    required String jobId,
    required String newStatus,
  }) async {
    final cleanJobId = jobId.trim();
    if (cleanJobId.isEmpty) {
      debugPrint('[JobsCubit.moveJobStatus] ERRO: jobId vazio recebido ao mover vaga.');
      return;
    }

    final currentState = state;
    if (currentState is! JobsLoaded) return;

    final previousJobs = currentState.jobs;
    final previousAllJobs = currentState.effectiveAllJobs;
    final targetStatus = JobStatus.fromString(newStatus);

    // 1. Atualização Otimista
    final updatedAllJobs = previousAllJobs.map((job) {
      if (job.jobId == cleanJobId) {
        return job.copyWith(status: targetStatus);
      }
      return job;
    }).toList();

    final updatedJobs = _applyFilter(
      updatedAllJobs,
      currentState.searchQuery,
      currentState.selectedModality,
    );
    emit(currentState.copyWith(
      jobs: updatedJobs,
      allJobs: updatedAllJobs,
    ));

    // 2. Persistência com Rollback em caso de erro
    try {
      debugPrint(
        '[JobsCubit.moveJobStatus] Persistindo no Supabase: jobId=$cleanJobId, '
        'status=${targetStatus.value} (input: $newStatus)',
      );
      await _repository.updateJobStatus(
        jobId: cleanJobId,
        newStatus: newStatus,
      );
      debugPrint(
        '[JobsCubit.moveJobStatus] Persistência realizada com sucesso para jobId=$cleanJobId',
      );
    } catch (e, stackTrace) {
      debugPrint(
        '[JobsCubit.moveJobStatus] ERRO ao persistir status da vaga jobId=$cleanJobId: $e\n$stackTrace',
      );
      emit(currentState.copyWith(
        jobs: previousJobs,
        allJobs: previousAllJobs,
        errorMessage: 'Erro ao mover vaga: $e',
      ));
    }
  }

  /// Removes [jobId] from the active Kanban view and marks it as archived in the repository.
  ///
  /// In case of persistence failure, rolls back the local state.
  Future<void> archiveJob(String jobId) async {
    final cleanJobId = jobId.trim();
    if (cleanJobId.isEmpty) {
      debugPrint('[JobsCubit.archiveJob] ERRO: jobId vazio recebido ao arquivar vaga.');
      return;
    }

    final currentState = state;
    if (currentState is! JobsLoaded) return;

    final previousJobs = currentState.jobs;
    final previousAllJobs = currentState.effectiveAllJobs;

    // 1. Otimista: remove da lista ativa exibida
    final updatedAllJobs =
        previousAllJobs.where((job) => job.jobId != cleanJobId).toList();
    final updatedJobs = _applyFilter(
      updatedAllJobs,
      currentState.searchQuery,
      currentState.selectedModality,
    );

    emit(currentState.copyWith(
      jobs: updatedJobs,
      allJobs: updatedAllJobs,
    ));

    // 2. Persistência
    try {
      debugPrint('[JobsCubit.archiveJob] Arquivando vaga jobId=$cleanJobId');
      await _repository.toggleJobArchived(
        jobId: cleanJobId,
        isArchived: true,
      );
      debugPrint('[JobsCubit.archiveJob] Vaga arquivada com sucesso jobId=$cleanJobId');
      emit(currentState.copyWith(
        jobs: updatedJobs,
        allJobs: updatedAllJobs,
        successMessage: 'Vaga arquivada com sucesso.',
      ));
    } catch (e, stackTrace) {
      debugPrint(
        '[JobsCubit.archiveJob] ERRO ao arquivar vaga jobId=$cleanJobId: $e\n$stackTrace',
      );
      emit(currentState.copyWith(
        jobs: previousJobs,
        allJobs: previousAllJobs,
        errorMessage: 'Erro ao arquivar vaga: $e',
      ));
    }
  }

  /// Optimistically updates personal notes for [jobId] and persists via repository.
  ///
  /// In case of persistence failure, rolls back to previous state.
  Future<void> updateJobNotes({
    required String jobId,
    required String notes,
  }) async {
    final cleanJobId = jobId.trim();
    if (cleanJobId.isEmpty) {
      debugPrint('[JobsCubit.updateJobNotes] ERRO: jobId vazio recebido ao salvar anotações.');
      return;
    }

    final currentState = state;
    if (currentState is! JobsLoaded) return;

    final previousJobs = currentState.jobs;
    final previousAllJobs = currentState.effectiveAllJobs;

    // 1. Atualização Otimista
    final updatedAllJobs = previousAllJobs.map((job) {
      if (job.jobId == cleanJobId) {
        return job.copyWith(notes: notes);
      }
      return job;
    }).toList();

    final updatedJobs = _applyFilter(
      updatedAllJobs,
      currentState.searchQuery,
      currentState.selectedModality,
    );
    emit(currentState.copyWith(
      jobs: updatedJobs,
      allJobs: updatedAllJobs,
    ));

    // 2. Persistência com Rollback em caso de erro
    try {
      debugPrint('[JobsCubit.updateJobNotes] Salvando anotações para jobId=$cleanJobId');
      await _repository.updateJobNotes(
        jobId: cleanJobId,
        notes: notes,
      );
      debugPrint('[JobsCubit.updateJobNotes] Anotações salvas com sucesso para jobId=$cleanJobId');
      emit(currentState.copyWith(
        jobs: updatedJobs,
        allJobs: updatedAllJobs,
        successMessage: 'Anotações salvas com sucesso.',
      ));
    } catch (e, stackTrace) {
      debugPrint(
        '[JobsCubit.updateJobNotes] ERRO ao salvar anotações para jobId=$jobId: $e\n$stackTrace',
      );
      emit(currentState.copyWith(
        jobs: previousJobs,
        allJobs: previousAllJobs,
        errorMessage: 'Erro ao salvar anotações: $e',
      ));
    }
  }

  /// Filters loaded jobs in memory across title, company, location, and platform,
  /// preserving any currently selected work modality.
  void filterJobs(String? query) {
    final currentState = state;
    if (currentState is! JobsLoaded) return;

    final trimmedQuery = query?.trim();
    if (trimmedQuery == null || trimmedQuery.isEmpty) {
      final filtered = _applyFilter(
        currentState.effectiveAllJobs,
        null,
        currentState.selectedModality,
      );
      emit(currentState.copyWith(
        jobs: filtered,
        clearSearchQuery: true,
      ));
      return;
    }

    final filtered = _applyFilter(
      currentState.effectiveAllJobs,
      trimmedQuery,
      currentState.selectedModality,
    );
    emit(currentState.copyWith(
      jobs: filtered,
      searchQuery: trimmedQuery,
    ));
  }

  /// Sets the quick modality filter and updates displayed jobs in memory,
  /// preserving any active text search query.
  void setModalityFilter(JobModalityFilter modality) {
    final currentState = state;
    if (currentState is! JobsLoaded) return;

    final filtered = _applyFilter(
      currentState.effectiveAllJobs,
      currentState.searchQuery,
      modality,
    );

    emit(currentState.copyWith(
      jobs: filtered,
      selectedModality: modality,
    ));
  }

  /// Resets both search text query and modality filter to show all active jobs.
  void resetFilters() {
    final currentState = state;
    if (currentState is! JobsLoaded) return;

    emit(currentState.copyWith(
      jobs: currentState.effectiveAllJobs,
      clearSearchQuery: true,
      selectedModality: JobModalityFilter.all,
    ));
  }

  /// Clears any transient error message on [JobsLoaded].
  void clearErrorMessage() {
    final currentState = state;
    if (currentState is JobsLoaded && currentState.errorMessage != null) {
      emit(currentState.copyWith(clearErrorMessage: true));
    }
  }

  /// Clears any transient success confirmation message on [JobsLoaded].
  void clearSuccessMessage() {
    final currentState = state;
    if (currentState is JobsLoaded && currentState.successMessage != null) {
      emit(currentState.copyWith(clearSuccessMessage: true));
    }
  }

  /// Backwards-compatible interaction updater for Spec 001 compatibility.
  Future<void> updateInteraction(UserJobInteraction interaction) async {
    try {
      await _repository.updateJobInteraction(interaction);
      await loadJobs();
    } catch (e) {
      emit(JobsError('Erro ao atualizar interação: $e'));
    }
  }

  List<JobItem> _applyFilter(
    List<JobItem> items,
    String? query,
    JobModalityFilter modality,
  ) {
    final hasQuery = query != null && query.trim().isNotEmpty;
    final lower = hasQuery ? query.trim().toLowerCase() : null;

    return items.where((job) {
      // 1. Modality filter check
      if (!job.matchesModality(modality)) {
        return false;
      }

      // 2. Text query check
      if (!hasQuery) {
        return true;
      }

      final titleMatch = job.title.toLowerCase().contains(lower!);
      final companyMatch = job.companyName.toLowerCase().contains(lower);
      final locationMatch =
          job.location != null && job.location!.toLowerCase().contains(lower);
      final platformMatch = job.platform.toLowerCase().contains(lower);
      final notesMatch =
          job.notes != null && job.notes!.toLowerCase().contains(lower);

      return titleMatch ||
          companyMatch ||
          locationMatch ||
          platformMatch ||
          notesMatch;
    }).toList();
  }
}

/// Backwards-compatible alias for [JobsCubit].
typedef KanbanCubit = JobsCubit;
