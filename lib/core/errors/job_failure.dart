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

/// Base failure for job markdown conversions.
class JobMarkdownFailure extends AppException {
  const JobMarkdownFailure(
    super.message, {
    super.code,
    super.details,
  });
}

/// Thrown when a network issue, timeout or unreachable server occurs during conversion.
class JobMarkdownNetworkFailure extends JobMarkdownFailure {
  const JobMarkdownNetworkFailure(
    super.message, {
    super.details,
  }) : super(code: 'MARKDOWN_NETWORK_ERROR');
}

/// Thrown when the job URL is empty or malformed.
class JobMarkdownInvalidUrlFailure extends JobMarkdownFailure {
  const JobMarkdownInvalidUrlFailure(
    super.message, {
    super.details,
  }) : super(code: 'MARKDOWN_INVALID_URL');
}

/// Thrown when the reader returns empty content or was blocked by bot protection.
class JobMarkdownEmptyFailure extends JobMarkdownFailure {
  const JobMarkdownEmptyFailure(
    super.message, {
    super.details,
  }) : super(code: 'MARKDOWN_EMPTY_CONTENT');
}

/// Thrown when the reader endpoint rate limit is reached (HTTP 429).
class JobMarkdownRateLimitFailure extends JobMarkdownFailure {
  const JobMarkdownRateLimitFailure(
    super.message, {
    super.details,
  }) : super(code: 'MARKDOWN_RATE_LIMIT');
}
