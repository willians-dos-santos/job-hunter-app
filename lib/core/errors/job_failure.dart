import 'app_exception.dart';

/// Thrown when an error occurs while querying or fetching jobs from Supabase.
class JobFetchFailure extends AppException {
  const JobFetchFailure(
    super.message, {
    super.code,
    super.details,
  });
}

/// Thrown when an error occurs while performing mutations or upserts on job interactions.
class JobMutationFailure extends AppException {
  const JobMutationFailure(
    super.message, {
    super.code,
    super.details,
  });
}

/// Thrown when a specific job ID is not found in the remote database.
class JobNotFoundFailure extends AppException {
  const JobNotFoundFailure(
    String jobId, {
    super.details,
  }) : super('Vaga não encontrada com o ID: $jobId', code: 'JOB_NOT_FOUND');
}
