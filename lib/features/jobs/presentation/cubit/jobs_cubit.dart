import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/user_job_interaction.dart';
import '../../domain/repositories/jobs_repository.dart';
import 'jobs_state.dart';

/// Cubit managing job list loading and funnel state transitions.
class JobsCubit extends Cubit<JobsState> {
  JobsCubit(this._repository) : super(const JobsInitial());

  final JobsRepository _repository;

  /// Loads the job list from repository.
  Future<void> loadJobs() async {
    emit(const JobsLoading());
    try {
      final jobs = await _repository.getJobs();
      emit(JobsLoaded(jobs));
    } catch (e) {
      emit(JobsError('Erro ao carregar vagas: $e'));
    }
  }

  /// Updates interaction (stage, notes) for a job and refreshes list.
  Future<void> updateInteraction(UserJobInteraction interaction) async {
    try {
      await _repository.updateJobInteraction(interaction);
      await loadJobs();
    } catch (e) {
      emit(JobsError('Erro ao atualizar interação: $e'));
    }
  }
}
