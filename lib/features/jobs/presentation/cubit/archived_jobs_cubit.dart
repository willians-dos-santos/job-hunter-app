import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/job_repository.dart';
import 'archived_jobs_state.dart';

/// Cubit responsible for loading, displaying, and restoring archived vacancies.
class ArchivedJobsCubit extends Cubit<ArchivedJobsState> {
  ArchivedJobsCubit(this._repository) : super(const ArchivedJobsInitial());

  final IJobRepository _repository;

  /// Exposes the underlying repository.
  IJobRepository get repository => _repository;

  /// Fetches all archived jobs (`is_archived = true`) for the authenticated user.
  Future<void> loadArchivedJobs() async {
    emit(const ArchivedJobsLoading());
    try {
      final archivedJobs = await _repository.getArchivedJobs();
      emit(ArchivedJobsLoaded(archivedJobs));
    } catch (e) {
      emit(ArchivedJobsError('Erro ao carregar vagas arquivadas: $e'));
    }
  }

  /// Optimistically restores [jobId] back to the active Kanban funnel,
  /// setting `isArchived: false` in Supabase with `onConflict: 'user_id,job_id'`.
  ///
  /// In case of failure, automatically rolls back to the previous list state.
  Future<void> restoreJob(String jobId) async {
    final currentState = state;
    if (currentState is! ArchivedJobsLoaded) return;

    final previousJobs = currentState.jobs;
    final updatedJobs =
        previousJobs.where((job) => job.jobId != jobId).toList();

    // 1. Otimista: remove da lista de arquivadas exibida
    emit(currentState.copyWith(
      jobs: updatedJobs,
      clearErrorMessage: true,
      clearSuccessMessage: true,
    ));

    // 2. Persistência
    try {
      await _repository.toggleJobArchived(
        jobId: jobId,
        isArchived: false,
      );
      emit(ArchivedJobsLoaded(
        updatedJobs,
        successMessage: 'Vaga restaurada com sucesso.',
      ));
    } catch (e) {
      emit(ArchivedJobsLoaded(
        previousJobs,
        errorMessage: 'Erro ao restaurar vaga: $e',
      ));
    }
  }

  /// Clears any transient error message on [ArchivedJobsLoaded].
  void clearErrorMessage() {
    final currentState = state;
    if (currentState is ArchivedJobsLoaded && currentState.errorMessage != null) {
      emit(currentState.copyWith(clearErrorMessage: true));
    }
  }

  /// Clears any transient success confirmation message on [ArchivedJobsLoaded].
  void clearSuccessMessage() {
    final currentState = state;
    if (currentState is ArchivedJobsLoaded && currentState.successMessage != null) {
      emit(currentState.copyWith(clearSuccessMessage: true));
    }
  }
}
