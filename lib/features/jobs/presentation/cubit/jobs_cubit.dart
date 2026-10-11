import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/job_item.dart';
import '../../domain/models/job_modality.dart';
import '../../domain/models/job_status.dart';
import '../../domain/models/user_job_interaction.dart';
import '../../domain/repositories/jobs_repository.dart';
import 'jobs_state.dart';

/// Cubit managing job loading, optimistic funnel moves, filtering, and archiving.
class JobsCubit extends Cubit<JobsState> {
  JobsCubit(this._repository) : super(const JobsInitial());

  final JobsRepository _repository;

  /// Loads jobs from repository, filtering out archived entries for the Kanban board.
  Future<void> loadJobs() async {
    emit(const JobsLoading());
    try {
      final rawJobs = await _repository.getJobs();
      final activeJobs = rawJobs.where((j) => !j.isArchived).toList();
      emit(JobsLoaded(activeJobs, allJobs: activeJobs));
    } catch (e) {
      emit(JobsError('Erro ao carregar vagas: $e'));
    }
  }

  /// Optimistically moves [jobId] to [newStatus] and persists via repository.
  ///
  /// In case of failure, automatically rolls back to the previous state.
  Future<void> moveJobStatus({
    required String jobId,
    required String newStatus,
  }) async {
    final currentState = state;
    if (currentState is! JobsLoaded) return;

    final previousJobs = currentState.jobs;
    final previousAllJobs = currentState.effectiveAllJobs;
    final targetStatus = JobStatus.fromString(newStatus);

    // 1. Atualização Otimista
    final updatedAllJobs = previousAllJobs.map((job) {
      if (job.jobId == jobId) {
        return job.copyWith(status: targetStatus);
      }
      return job;
    }).toList();

    final updatedJobs = _applyFilter(
      updatedAllJobs,
      currentState.searchQuery,
      currentState.selectedModality,
    );
    emit(JobsLoaded(
      updatedJobs,
      allJobs: updatedAllJobs,
      searchQuery: currentState.searchQuery,
      selectedModality: currentState.selectedModality,
    ));

    // 2. Persistência com Rollback em caso de erro
    try {
      await _repository.updateJobStatus(
        jobId: jobId,
        newStatus: newStatus,
      );
    } catch (e) {
      emit(JobsLoaded(
        previousJobs,
        allJobs: previousAllJobs,
        searchQuery: currentState.searchQuery,
        selectedModality: currentState.selectedModality,
        errorMessage: 'Erro ao mover vaga: $e',
      ));
    }
  }

  /// Removes [jobId] from the active Kanban view and marks it as archived in the repository.
  ///
  /// In case of persistence failure, rolls back the local state.
  Future<void> archiveJob(String jobId) async {
    final currentState = state;
    if (currentState is! JobsLoaded) return;

    final previousJobs = currentState.jobs;
    final previousAllJobs = currentState.effectiveAllJobs;

    // 1. Otimista: remove da lista ativa exibida
    final updatedAllJobs =
        previousAllJobs.where((job) => job.jobId != jobId).toList();
    final updatedJobs = _applyFilter(
      updatedAllJobs,
      currentState.searchQuery,
      currentState.selectedModality,
    );

    emit(JobsLoaded(
      updatedJobs,
      allJobs: updatedAllJobs,
      searchQuery: currentState.searchQuery,
      selectedModality: currentState.selectedModality,
    ));

    // 2. Persistência
    try {
      await _repository.toggleJobArchived(
        jobId: jobId,
        isArchived: true,
      );
      emit(JobsLoaded(
        updatedJobs,
        allJobs: updatedAllJobs,
        searchQuery: currentState.searchQuery,
        selectedModality: currentState.selectedModality,
        successMessage: 'Vaga arquivada com sucesso.',
      ));
    } catch (e) {
      emit(JobsLoaded(
        previousJobs,
        allJobs: previousAllJobs,
        searchQuery: currentState.searchQuery,
        selectedModality: currentState.selectedModality,
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
    final currentState = state;
    if (currentState is! JobsLoaded) return;

    final previousJobs = currentState.jobs;
    final previousAllJobs = currentState.effectiveAllJobs;

    // 1. Atualização Otimista
    final updatedAllJobs = previousAllJobs.map((job) {
      if (job.jobId == jobId) {
        return job.copyWith(notes: notes);
      }
      return job;
    }).toList();

    final updatedJobs = _applyFilter(
      updatedAllJobs,
      currentState.searchQuery,
      currentState.selectedModality,
    );
    emit(JobsLoaded(
      updatedJobs,
      allJobs: updatedAllJobs,
      searchQuery: currentState.searchQuery,
      selectedModality: currentState.selectedModality,
    ));

    // 2. Persistência com Rollback em caso de erro
    try {
      await _repository.updateJobNotes(
        jobId: jobId,
        notes: notes,
      );
      emit(JobsLoaded(
        updatedJobs,
        allJobs: updatedAllJobs,
        searchQuery: currentState.searchQuery,
        selectedModality: currentState.selectedModality,
        successMessage: 'Anotações salvas com sucesso.',
      ));
    } catch (e) {
      emit(JobsLoaded(
        previousJobs,
        allJobs: previousAllJobs,
        searchQuery: currentState.searchQuery,
        selectedModality: currentState.selectedModality,
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
