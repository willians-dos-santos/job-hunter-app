import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/services/env_config.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/models/job_item.dart';
import '../../domain/models/job_status.dart';
import '../../domain/models/user_job_interaction.dart';

/// Contract for remote Supabase queries and mutations on jobs.
abstract class IJobRemoteDataSource {
  /// Queries enriched vacancies from `v_user_jobs`.
  ///
  /// Supports offset pagination, funnel status filtering, text search across
  /// title or company name, optional user filter, and defaults to descending order by publication date.
  Future<List<JobItem>> getJobs({
    int limit = 20,
    int offset = 0,
    String? statusFilter,
    String? query,
    String? userId,
  });

  /// Queries archived vacancies from `v_user_jobs` where `is_archived = true`
  /// associated with the authenticated user.
  Future<List<JobItem>> getArchivedJobs({
    int limit = 50,
    int offset = 0,
    String? userId,
  });

  /// Queries a single job from `v_user_jobs` by its [id].
  ///
  /// Throws [JobNotFoundFailure] if not found, or [JobFetchFailure] on query error.
  Future<JobItem> getJobById(String id, {String? userId});

  /// Updates or inserts the candidate status in `user_job_interactions`.
  Future<void> updateJobStatus({
    required String jobId,
    required String newStatus,
    String? userId,
  });

  /// Updates or inserts candidate notes in `user_job_interactions`.
  Future<void> updateJobNotes({
    required String jobId,
    required String notes,
    String? userId,
  });

  /// Marks or unmarks a job as archived in `user_job_interactions`.
  Future<void> toggleJobArchived({
    required String jobId,
    required bool isArchived,
    String? userId,
  });

  /// Upserts the full interaction model into `user_job_interactions`.
  Future<void> upsertInteraction(
    UserJobInteraction interaction, {
    String? userId,
  });

  /// Backwards-compatible alias for [getJobs].
  Future<List<JobItem>> fetchJobs({
    int limit = 50,
    int offset = 0,
    String? userId,
  }) =>
      getJobs(limit: limit, offset: offset, userId: userId);

  /// Backwards-compatible alias for [getJobById].
  Future<JobItem?> fetchJobById(String jobId, {String? userId}) =>
      getJobById(jobId, userId: userId);
}

/// Backwards-compatible alias for [IJobRemoteDataSource].
typedef JobsRemoteDataSource = IJobRemoteDataSource;

/// Implementation of [IJobRemoteDataSource] using the official Supabase Flutter client.
class JobRemoteDataSource implements IJobRemoteDataSource {
  JobRemoteDataSource([
    SupabaseClient? client,
    String? userId,
  ])  : _providedClient = client,
        _configuredUserId = userId;

  final SupabaseClient? _providedClient;
  final String? _configuredUserId;

  SupabaseClient get _client => _providedClient ?? SupabaseService.client;

  String? _tryGetAuthUserId() {
    try {
      final authId = _client.auth.currentUser?.id.trim();
      if (authId != null && authId.isNotEmpty) {
        return authId;
      }
    } catch (_) {
      // Ignora erro em ambientes de teste sem stub de auth
    }
    return null;
  }

  /// Effective user ID resolved from explicit injection, Supabase Auth session, or [EnvConfig.supabaseUserId].
  String? get currentUserId {
    // 1. Explicitamente injetado
    final configured = _configuredUserId?.trim();
    if (configured != null && configured.isNotEmpty) {
      return configured;
    }
    // 2. Usuário autenticado na sessão do Supabase Auth
    final authId = _tryGetAuthUserId();
    if (authId != null && authId.isNotEmpty) {
      return authId;
    }
    // 3. Fallback para EnvConfig (.env SUPABASE_USER_ID)
    if (EnvConfig.isInitialized) {
      final envId = EnvConfig.supabaseUserId?.trim();
      if (envId != null && envId.isNotEmpty) {
        return envId;
      }
    }
    return null;
  }

  String? _resolveUserId(String? overrideUserId) {
    final candidate = overrideUserId ?? currentUserId;
    if (candidate != null && candidate.trim().isNotEmpty) {
      return candidate.trim();
    }
    return null;
  }

  @override
  Future<List<JobItem>> getJobs({
    int limit = 20,
    int offset = 0,
    String? statusFilter,
    String? query,
    String? userId,
  }) async {
    try {
      final effectiveUserId = _resolveUserId(userId);
      debugPrint(
        '[JobRemoteDataSource.getJobs] Querying ${AppConstants.userJobsView} with params: '
        'limit=$limit, offset=$offset, statusFilter=$statusFilter, query=$query, userId=$effectiveUserId',
      );

      dynamic builder = _client
          .from(AppConstants.userJobsView)
          .select();

      if (effectiveUserId != null) {
        builder = builder.or('user_id.is.null,user_id.eq.$effectiveUserId');
      }

      if (statusFilter != null && statusFilter.trim().isNotEmpty) {
        builder = builder.eq('status', statusFilter.trim());
      }

      if (query != null && query.trim().isNotEmpty) {
        final cleanQuery = query.trim();
        builder = builder.or(
          'title.ilike.%$cleanQuery%,company.ilike.%$cleanQuery%',
        );
      }

      builder = builder.order('published_at', ascending: false);

      final start = offset < 0 ? 0 : offset;
      if (limit > 0) {
        builder = builder.range(start, start + limit - 1);
      }

      final response = await builder;
      final rawList = response is List ? response : <dynamic>[];
      debugPrint(
        '[JobRemoteDataSource.getJobs] Response raw received (${rawList.length} items): $response',
      );

      final list = rawList.cast<Map<String, dynamic>>();
      return list.map(JobItem.fromJson).toList();
    } on PostgrestException catch (e) {
      debugPrint(
        '[JobRemoteDataSource.getJobs] PostgrestException: ${e.message} (code: ${e.code}, details: ${e.details})',
      );
      throw JobFetchFailure(e.message, code: e.code, details: e.details);
    } catch (e) {
      debugPrint('[JobRemoteDataSource.getJobs] Error: $e');
      if (e is AppException) rethrow;
      throw JobFetchFailure('Erro ao buscar vagas: $e', details: e);
    }
  }

  @override
  Future<List<JobItem>> getArchivedJobs({
    int limit = 50,
    int offset = 0,
    String? userId,
  }) async {
    try {
      final effectiveUserId = _resolveUserId(userId);
      debugPrint(
        '[JobRemoteDataSource.getArchivedJobs] Querying ${AppConstants.userJobsView} for archived jobs: '
        'limit=$limit, offset=$offset, userId=$effectiveUserId',
      );

      dynamic builder = _client
          .from(AppConstants.userJobsView)
          .select()
          .eq('status', 'archived');

      if (effectiveUserId != null) {
        builder = builder.or('user_id.is.null,user_id.eq.$effectiveUserId');
      }

      builder = builder.order('published_at', ascending: false);

      final start = offset < 0 ? 0 : offset;
      if (limit > 0) {
        builder = builder.range(start, start + limit - 1);
      }

      final response = await builder;
      final rawList = response is List ? response : <dynamic>[];
      debugPrint(
        '[JobRemoteDataSource.getArchivedJobs] Response raw received (${rawList.length} items): $response',
      );

      final list = rawList.cast<Map<String, dynamic>>();
      return list.map(JobItem.fromJson).toList();
    } on PostgrestException catch (e) {
      debugPrint(
        '[JobRemoteDataSource.getArchivedJobs] PostgrestException: ${e.message} (code: ${e.code}, details: ${e.details})',
      );
      throw JobFetchFailure(e.message, code: e.code, details: e.details);
    } catch (e) {
      debugPrint('[JobRemoteDataSource.getArchivedJobs] Error: $e');
      if (e is AppException) rethrow;
      throw JobFetchFailure('Erro ao buscar vagas arquivadas: $e', details: e);
    }
  }

  @override
  Future<JobItem> getJobById(String id, {String? userId}) async {
    try {
      final effectiveUserId = _resolveUserId(userId);
      debugPrint(
        '[JobRemoteDataSource.getJobById] Querying ${AppConstants.userJobsView} for job_id=$id, userId=$effectiveUserId',
      );

      dynamic builder = _client
          .from(AppConstants.userJobsView)
          .select()
          .eq('job_id', id);

      if (effectiveUserId != null) {
        builder = builder.or('user_id.is.null,user_id.eq.$effectiveUserId');
      }

      final response = await builder.maybeSingle();
      debugPrint(
        '[JobRemoteDataSource.getJobById] Response raw received: $response',
      );

      if (response == null) {
        throw JobNotFoundFailure(id);
      }

      return JobItem.fromJson(response);
    } on PostgrestException catch (e) {
      debugPrint(
        '[JobRemoteDataSource.getJobById] PostgrestException: ${e.message} (code: ${e.code})',
      );
      throw JobFetchFailure(e.message, code: e.code, details: e.details);
    } catch (e) {
      debugPrint('[JobRemoteDataSource.getJobById] Error: $e');
      if (e is AppException) rethrow;
      throw JobFetchFailure('Erro ao buscar vaga: $e', details: e);
    }
  }

  @override
  Future<void> updateJobStatus({
    required String jobId,
    required String newStatus,
    String? userId,
  }) async {
    try {
      final effectiveUserId = _resolveUserId(userId);
      final normalizedStatus = JobStatus.fromString(newStatus).value;

      const allowedStatuses = {
        'new',
        'applied',
        'interviewing',
        'offer',
        'rejected',
      };
      if (!allowedStatuses.contains(normalizedStatus)) {
        debugPrint(
          '[JobRemoteDataSource.updateJobStatus] AVISO: status "$normalizedStatus" '
          'não é um dos valores permitidos pela constraint do banco: $allowedStatuses',
        );
      }

      final payload = <String, dynamic>{
        'job_id': jobId,
        if (effectiveUserId != null && effectiveUserId.isNotEmpty)
          'user_id': effectiveUserId,
        'status': normalizedStatus,
      };

      if (normalizedStatus == 'applied') {
        payload['applied_at'] = DateTime.now().toUtc().toIso8601String();
      }

      if (effectiveUserId == null || effectiveUserId.isEmpty) {
        debugPrint(
          '[JobRemoteDataSource.updateJobStatus] ALERTA CRÍTICO: user_id está nulo/vazio ao montar payload! '
          'auth.currentUser?.id=${_tryGetAuthUserId()}, '
          'configured=$_configuredUserId, '
          'EnvConfig=${EnvConfig.isInitialized ? EnvConfig.supabaseUserId : "não inicializado"}. '
          'O upsert em user_job_interactions exige user_id para satisfazer onConflict: "user_id,job_id".',
        );
      }

      debugPrint(
        '[JobRemoteDataSource.updateJobStatus] status: "$normalizedStatus" (raw: "$newStatus"), payload: $payload',
      );
      debugPrint(
        '[JobRemoteDataSource.updateJobStatus] Upserting to ${AppConstants.userJobInteractionsTable} '
        'com onConflict "user_id,job_id": $payload',
      );

      await _client
          .from(AppConstants.userJobInteractionsTable)
          .upsert(payload, onConflict: 'user_id,job_id');

      debugPrint(
        '[JobRemoteDataSource.updateJobStatus] Upsert concluído com sucesso para jobId=$jobId, status=$normalizedStatus',
      );
    } on PostgrestException catch (e) {
      debugPrint(
        '[JobRemoteDataSource.updateJobStatus] PostgrestException ao atualizar status da vaga ($jobId):\n'
        '  message: ${e.message}\n'
        '  code: ${e.code}\n'
        '  details: ${e.details}\n'
        '  hint: ${e.hint}',
      );
      throw JobMutationFailure(
        e.message,
        code: e.code,
        details: '${e.details ?? ''} ${e.hint ?? ''}'.trim(),
      );
    } catch (e, stackTrace) {
      debugPrint(
        '[JobRemoteDataSource.updateJobStatus] Erro inesperado ao atualizar status (jobId=$jobId): $e\n$stackTrace',
      );
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
    String? userId,
  }) async {
    try {
      final effectiveUserId = _resolveUserId(userId);
      final payload = <String, dynamic>{
        'job_id': jobId,
        if (effectiveUserId != null && effectiveUserId.isNotEmpty)
          'user_id': effectiveUserId,
        'notes': notes,
      };

      if (effectiveUserId == null || effectiveUserId.isEmpty) {
        debugPrint(
          '[JobRemoteDataSource.updateJobNotes] ALERTA CRÍTICO: user_id está nulo/vazio ao montar payload! '
          'auth.currentUser?.id=${_tryGetAuthUserId()}, configured=$_configuredUserId',
        );
      }

      debugPrint(
        '[JobRemoteDataSource.updateJobNotes] Upserting to ${AppConstants.userJobInteractionsTable} '
        'com onConflict "user_id,job_id": $payload',
      );
      await _client
          .from(AppConstants.userJobInteractionsTable)
          .upsert(payload, onConflict: 'user_id,job_id');
      debugPrint('[JobRemoteDataSource.updateJobNotes] Upsert successful');
    } on PostgrestException catch (e) {
      debugPrint(
        '[JobRemoteDataSource.updateJobNotes] PostgrestException (jobId=$jobId):\n'
        '  message: ${e.message}\n'
        '  code: ${e.code}\n'
        '  details: ${e.details}\n'
        '  hint: ${e.hint}',
      );
      throw JobMutationFailure(
        e.message,
        code: e.code,
        details: '${e.details ?? ''} ${e.hint ?? ''}'.trim(),
      );
    } catch (e, stackTrace) {
      debugPrint('[JobRemoteDataSource.updateJobNotes] Error: $e\n$stackTrace');
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
    String? userId,
  }) async {
    try {
      final effectiveUserId = _resolveUserId(userId);
      final payload = <String, dynamic>{
        'job_id': jobId,
        if (effectiveUserId != null && effectiveUserId.isNotEmpty)
          'user_id': effectiveUserId,
        'status': isArchived ? 'archived' : 'new',
      };

      if (effectiveUserId == null || effectiveUserId.isEmpty) {
        debugPrint(
          '[JobRemoteDataSource.toggleJobArchived] ALERTA CRÍTICO: user_id está nulo/vazio ao montar payload! '
          'auth.currentUser?.id=${_tryGetAuthUserId()}, configured=$_configuredUserId',
        );
      }

      debugPrint(
        '[JobRemoteDataSource.toggleJobArchived] Upserting to ${AppConstants.userJobInteractionsTable} '
        'com onConflict "user_id,job_id": $payload',
      );
      await _client
          .from(AppConstants.userJobInteractionsTable)
          .upsert(payload, onConflict: 'user_id,job_id');
      debugPrint('[JobRemoteDataSource.toggleJobArchived] Upsert successful');
    } on PostgrestException catch (e) {
      debugPrint(
        '[JobRemoteDataSource.toggleJobArchived] PostgrestException (jobId=$jobId):\n'
        '  message: ${e.message}\n'
        '  code: ${e.code}\n'
        '  details: ${e.details}\n'
        '  hint: ${e.hint}',
      );
      throw JobMutationFailure(
        e.message,
        code: e.code,
        details: '${e.details ?? ''} ${e.hint ?? ''}'.trim(),
      );
    } catch (e, stackTrace) {
      debugPrint('[JobRemoteDataSource.toggleJobArchived] Error: $e\n$stackTrace');
      if (e is AppException) rethrow;
      throw JobMutationFailure(
        'Erro ao atualizar arquivamento da vaga: $e',
        details: e,
      );
    }
  }

  @override
  Future<void> upsertInteraction(
    UserJobInteraction interaction, {
    String? userId,
  }) async {
    try {
      final effectiveUserId = _resolveUserId(userId ?? interaction.userId);
      final payload = interaction.toJson();
      if (effectiveUserId != null && effectiveUserId.isNotEmpty) {
        payload['user_id'] = effectiveUserId;
      }
      if (payload.containsKey('status') && payload['status'] != null) {
        payload['status'] =
            JobStatus.fromString(payload['status'].toString()).value;
      }

      debugPrint(
        '[JobRemoteDataSource.upsertInteraction] status: "${payload['status']}", payload: $payload',
      );
      debugPrint(
        '[JobRemoteDataSource.upsertInteraction] Upserting to ${AppConstants.userJobInteractionsTable} '
        'com onConflict "user_id,job_id": $payload',
      );
      await _client
          .from(AppConstants.userJobInteractionsTable)
          .upsert(payload, onConflict: 'user_id,job_id');
      debugPrint('[JobRemoteDataSource.upsertInteraction] Upsert successful');
    } on PostgrestException catch (e) {
      debugPrint(
        '[JobRemoteDataSource.upsertInteraction] PostgrestException (jobId=${interaction.jobId}):\n'
        '  message: ${e.message}\n'
        '  code: ${e.code}\n'
        '  details: ${e.details}\n'
        '  hint: ${e.hint}',
      );
      throw JobMutationFailure(
        e.message,
        code: e.code,
        details: '${e.details ?? ''} ${e.hint ?? ''}'.trim(),
      );
    } catch (e, stackTrace) {
      debugPrint('[JobRemoteDataSource.upsertInteraction] Error: $e\n$stackTrace');
      if (e is AppException) rethrow;
      throw JobMutationFailure(
        'Erro ao registrar interação da vaga: $e',
        details: e,
      );
    }
  }

  @override
  Future<List<JobItem>> fetchJobs({
    int limit = 50,
    int offset = 0,
    String? userId,
  }) =>
      getJobs(limit: limit, offset: offset, userId: userId);

  @override
  Future<JobItem?> fetchJobById(String jobId, {String? userId}) =>
      getJobById(jobId, userId: userId);
}

/// Backwards-compatible aliases
typedef JobRemoteDataSourceImpl = JobRemoteDataSource;
typedef JobsRemoteDataSourceImpl = JobRemoteDataSource;
