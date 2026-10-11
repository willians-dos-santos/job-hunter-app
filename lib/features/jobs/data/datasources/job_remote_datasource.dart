import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/models/job_item.dart';
import '../../domain/models/user_job_interaction.dart';

/// Contract for remote Supabase queries and mutations on jobs.
abstract class IJobRemoteDataSource {
  /// Queries enriched vacancies from `v_user_jobs`.
  ///
  /// Supports offset pagination, funnel status filtering, text search across
  /// title or company name, and defaults to descending order by publication/creation date.
  Future<List<JobItem>> getJobs({
    int limit = 20,
    int offset = 0,
    String? statusFilter,
    String? query,
  });

  /// Queries a single job from `v_user_jobs` by its [id].
  ///
  /// Throws [JobNotFoundFailure] if not found, or [JobFetchFailure] on query error.
  Future<JobItem> getJobById(String id);

  /// Updates or inserts the candidate status in `user_job_interactions`.
  Future<void> updateJobStatus({
    required String jobId,
    required String newStatus,
  });

  /// Updates or inserts candidate notes in `user_job_interactions`.
  Future<void> updateJobNotes({
    required String jobId,
    required String notes,
  });

  /// Marks or unmarks a job as archived in `user_job_interactions`.
  Future<void> toggleJobArchived({
    required String jobId,
    required bool isArchived,
  });

  /// Upserts the full interaction model into `user_job_interactions`.
  Future<void> upsertInteraction(UserJobInteraction interaction);

  /// Backwards-compatible alias for [getJobs].
  Future<List<JobItem>> fetchJobs({int limit = 50, int offset = 0}) =>
      getJobs(limit: limit, offset: offset);

  /// Backwards-compatible alias for [getJobById].
  Future<JobItem?> fetchJobById(String jobId) => getJobById(jobId);
}

/// Backwards-compatible alias for [IJobRemoteDataSource].
typedef JobsRemoteDataSource = IJobRemoteDataSource;

/// Implementation of [IJobRemoteDataSource] using the official Supabase Flutter client.
class JobRemoteDataSource implements IJobRemoteDataSource {
  JobRemoteDataSource([SupabaseClient? client])
      : _client = client ?? SupabaseService.client;

  final SupabaseClient _client;

  @override
  Future<List<JobItem>> getJobs({
    int limit = 20,
    int offset = 0,
    String? statusFilter,
    String? query,
  }) async {
    try {
      dynamic builder = _client
          .from(AppConstants.userJobsView)
          .select();

      if (statusFilter != null && statusFilter.trim().isNotEmpty) {
        builder = builder.eq('status', statusFilter.trim());
      }

      if (query != null && query.trim().isNotEmpty) {
        final cleanQuery = query.trim();
        builder = builder.or(
          'title.ilike.%$cleanQuery%,company_name.ilike.%$cleanQuery%',
        );
      }

      builder = builder.order('created_at', ascending: false);

      final start = offset < 0 ? 0 : offset;
      if (limit > 0) {
        builder = builder.range(start, start + limit - 1);
      }

      final response = await builder;
      final list = (response as List).cast<Map<String, dynamic>>();
      return list.map(JobItem.fromJson).toList();
    } on PostgrestException catch (e) {
      throw JobFetchFailure(e.message, code: e.code, details: e.details);
    } catch (e) {
      if (e is AppException) rethrow;
      throw JobFetchFailure('Erro ao buscar vagas: $e', details: e);
    }
  }

  @override
  Future<JobItem> getJobById(String id) async {
    try {
      final response = await _client
          .from(AppConstants.userJobsView)
          .select()
          .eq('job_id', id)
          .maybeSingle();

      if (response == null) {
        throw JobNotFoundFailure(id);
      }

      return JobItem.fromJson(response);
    } on PostgrestException catch (e) {
      throw JobFetchFailure(e.message, code: e.code, details: e.details);
    } catch (e) {
      if (e is AppException) rethrow;
      throw JobFetchFailure('Erro ao buscar vaga: $e', details: e);
    }
  }

  @override
  Future<void> updateJobStatus({
    required String jobId,
    required String newStatus,
  }) async {
    try {
      final payload = <String, dynamic>{
        'job_id': jobId,
        'status': newStatus,
      };

      if (newStatus == 'applied') {
        payload['applied_at'] = DateTime.now().toUtc().toIso8601String();
      }

      await _client
          .from(AppConstants.userJobInteractionsTable)
          .upsert(payload, onConflict: 'job_id');
    } on PostgrestException catch (e) {
      throw JobMutationFailure(e.message, code: e.code, details: e.details);
    } catch (e) {
      if (e is AppException) rethrow;
      throw JobMutationFailure(
        'Erro ao atualizar status da vaga: $e',
        details: e,
      );
    }
  }

  @override
  Future<void> updateJobNotes({
    required String jobId,
    required String notes,
  }) async {
    try {
      final payload = <String, dynamic>{
        'job_id': jobId,
        'notes': notes,
      };

      await _client
          .from(AppConstants.userJobInteractionsTable)
          .upsert(payload, onConflict: 'job_id');
    } on PostgrestException catch (e) {
      throw JobMutationFailure(e.message, code: e.code, details: e.details);
    } catch (e) {
      if (e is AppException) rethrow;
      throw JobMutationFailure(
        'Erro ao atualizar anotações da vaga: $e',
        details: e,
      );
    }
  }

  @override
  Future<void> toggleJobArchived({
    required String jobId,
    required bool isArchived,
  }) async {
    try {
      final payload = <String, dynamic>{
        'job_id': jobId,
        'is_archived': isArchived,
      };

      await _client
          .from(AppConstants.userJobInteractionsTable)
          .upsert(payload, onConflict: 'job_id');
    } on PostgrestException catch (e) {
      throw JobMutationFailure(e.message, code: e.code, details: e.details);
    } catch (e) {
      if (e is AppException) rethrow;
      throw JobMutationFailure(
        'Erro ao atualizar arquivamento da vaga: $e',
        details: e,
      );
    }
  }

  @override
  Future<void> upsertInteraction(UserJobInteraction interaction) async {
    try {
      await _client
          .from(AppConstants.userJobInteractionsTable)
          .upsert(interaction.toJson(), onConflict: 'job_id');
    } on PostgrestException catch (e) {
      throw JobMutationFailure(e.message, code: e.code, details: e.details);
    } catch (e) {
      if (e is AppException) rethrow;
      throw JobMutationFailure(
        'Erro ao registrar interação da vaga: $e',
        details: e,
      );
    }
  }

  @override
  Future<List<JobItem>> fetchJobs({int limit = 50, int offset = 0}) =>
      getJobs(limit: limit, offset: offset);

  @override
  Future<JobItem?> fetchJobById(String jobId) => getJobById(jobId);
}

/// Backwards-compatible aliases
typedef JobRemoteDataSourceImpl = JobRemoteDataSource;
typedef JobsRemoteDataSourceImpl = JobRemoteDataSource;
