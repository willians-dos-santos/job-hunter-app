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

  /// Queries triage inbox vacancies from `v_new_jobs`.
  ///
  /// Ordered by `created_at desc` with dedicated offset pagination.
  Future<List<JobItem>> getNewJobs({
    int limit = 20,
    int offset = 0,
    String? userId,
  });

  /// Queries active pipeline vacancies from `v_active_pipeline_jobs`.
  ///
  /// Ordered by `interaction_updated_at desc` without aggressive pagination limits.
  Future<List<JobItem>> getActivePipelineJobs({
    int? limit,
    int? offset,
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
  Future<List<JobItem>> getNewJobs({
    int limit = 20,
    int offset = 0,
    String? userId,
  }) async {
    try {
      final effectiveUserId = _resolveUserId(userId);
      debugPrint(
        '[JobRemoteDataSource.getNewJobs] Querying ${AppConstants.newJobsView} with params: '
        'limit=$limit, offset=$offset, userId=$effectiveUserId',
      );

      dynamic builder = _client
          .from(AppConstants.newJobsView)
          .select();

      builder = builder.order('created_at', ascending: false);

      final start = offset < 0 ? 0 : offset;
      if (limit > 0) {
        builder = builder.range(start, start + limit - 1);
      }

      final response = await builder;
      final rawList = response is List ? response : <dynamic>[];
      debugPrint(
        '[JobRemoteDataSource.getNewJobs] Response raw received (${rawList.length} items): $response',
      );

      final list = rawList.cast<Map<String, dynamic>>();
      return list.map(JobItem.fromJson).toList();
    } on PostgrestException catch (e) {
      debugPrint(
        '[JobRemoteDataSource.getNewJobs] PostgrestException: ${e.message} (code: ${e.code}, details: ${e.details})',
      );
      throw JobFetchFailure(e.message, code: e.code, details: e.details);
    } catch (e) {
      debugPrint('[JobRemoteDataSource.getNewJobs] Error: $e');
      if (e is AppException) rethrow;
      throw JobFetchFailure('Erro ao buscar vagas novas: $e', details: e);
    }
  }

  @override
  Future<List<JobItem>> getActivePipelineJobs({
    int? limit,
    int? offset,
    String? userId,
  }) async {
    try {
      final effectiveUserId = _resolveUserId(userId);
      debugPrint(
        '[JobRemoteDataSource.getActivePipelineJobs] Querying ${AppConstants.activePipelineJobsView} with params: '
        'limit=$limit, offset=$offset, userId=$effectiveUserId',
      );

      dynamic builder = _client
          .from(AppConstants.activePipelineJobsView)
          .select();

      builder = builder.order('interaction_updated_at', ascending: false);

      if (offset != null && offset >= 0 && limit != null && limit > 0) {
        builder = builder.range(offset, offset + limit - 1);
      } else if (limit != null && limit > 0) {
        builder = builder.range(0, limit - 1);
      }

      final response = await builder;
      // Log detalhado para diagnóstico do pipeline ativo
      // ignore: avoid_print
      print('[KanbanDebug] Active Pipeline response: $response');

      final rawList = response is List ? response : <dynamic>[];
      debugPrint(
        '[JobRemoteDataSource.getActivePipelineJobs] Response raw received (${rawList.length} items): $response',
      );

      final authUser = _tryGetAuthUserId();
      if (rawList.isEmpty && authUser == null && effectiveUserId != null && effectiveUserId.isNotEmpty) {
        debugPrint(
          '[KanbanDebug] AVISO: auth.currentUser é nulo. A view ${AppConstants.activePipelineJobsView} '
          'depende de auth.uid() no PostgreSQL e retornou lista vazia. '
          'Executando fallback para ${AppConstants.userJobsView} usando effectiveUserId=$effectiveUserId',
        );
        try {
          dynamic fallbackBuilder = _client
              .from(AppConstants.userJobsView)
              .select()
              .neq('status', 'new')
              .eq('is_archived', false)
              .eq('user_id', effectiveUserId);

          fallbackBuilder = fallbackBuilder.order('interaction_updated_at', ascending: false);

          if (offset != null && offset >= 0 && limit != null && limit > 0) {
            fallbackBuilder = fallbackBuilder.range(offset, offset + limit - 1);
          } else if (limit != null && limit > 0) {
            fallbackBuilder = fallbackBuilder.range(0, limit - 1);
          }

          final fallbackResponse = await fallbackBuilder;
          // ignore: avoid_print
          print('[KanbanDebug] Active Pipeline response (from fallback ${AppConstants.userJobsView}): $fallbackResponse');
          final fallbackList = fallbackResponse is List ? fallbackResponse : <dynamic>[];
          final list = fallbackList.cast<Map<String, dynamic>>();
          return list.map(JobItem.fromJson).toList();
        } catch (fallbackError) {
          debugPrint('[KanbanDebug] Erro no fallback de pipeline ativo em ${AppConstants.userJobsView}: $fallbackError');
        }
      }

      final list = rawList.cast<Map<String, dynamic>>();
      return list.map(JobItem.fromJson).toList();
    } on PostgrestException catch (e) {
      debugPrint(
        '[JobRemoteDataSource.getActivePipelineJobs] PostgrestException: ${e.message} (code: ${e.code}, details: ${e.details})',
      );
      throw JobFetchFailure(e.message, code: e.code, details: e.details);
    } catch (e) {
      debugPrint('[JobRemoteDataSource.getActivePipelineJobs] Error: $e');
      if (e is AppException) rethrow;
      throw JobFetchFailure('Erro ao buscar pipeline ativo: $e', details: e);
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
    final cleanId = id.trim();
    if (cleanId.isEmpty) {
      throw JobNotFoundFailure(id);
    }

    try {
      final effectiveUserId = _resolveUserId(userId);
      debugPrint(
        '[JobRemoteDataSource.getJobById] Fetching job for id=$cleanId, userId=$effectiveUserId',
      );

      bool isTableOrViewUnavailable(PostgrestException e) {
        final code = e.code?.toUpperCase();
        return code == '42P01' ||
            code == '42501' ||
            code == 'PGRST200' ||
            code == 'PGRST204' ||
            code == 'PGRST205';
      }

      Map<String, dynamic>? jobData;

      // 1. Consulta prioritária na tabela canônica 'jobs' filtrando por 'id'
      try {
        final jobResponse = await _client
            .from(AppConstants.jobsTable)
            .select()
            .eq('id', cleanId)
            .maybeSingle();

        if (jobResponse != null) {
          jobData = Map<String, dynamic>.from(jobResponse);
          jobData['job_id'] = jobData['id'] ?? cleanId;

          // Se houver usuário ativo, busca interação específica em user_job_interactions
          if (effectiveUserId != null && effectiveUserId.isNotEmpty) {
            try {
              final interactionResponse = await _client
                  .from(AppConstants.userJobInteractionsTable)
                  .select()
                  .eq('job_id', cleanId)
                  .eq('user_id', effectiveUserId)
                  .maybeSingle();

              if (interactionResponse != null) {
                jobData['status'] = interactionResponse['status'];
                jobData['notes'] = interactionResponse['notes'];
                jobData['applied_at'] = interactionResponse['applied_at'];
                jobData['is_archived'] = interactionResponse['is_archived'];
                jobData['user_id'] =
                    interactionResponse['user_id'] ?? effectiveUserId;
                jobData['interaction_updated_at'] =
                    interactionResponse['updated_at'];
              }
            } catch (interactionError) {
              debugPrint(
                '[JobRemoteDataSource.getJobById] Aviso ao consultar interações da vaga: $interactionError',
              );
            }
          }
        }
      } on PostgrestException catch (e) {
        if (!isTableOrViewUnavailable(e)) rethrow;
        debugPrint(
          '[JobRemoteDataSource.getJobById] Tabela jobs indisponível (${e.code}). Tentando views...',
        );
      }

      // 2. Se não encontrou na tabela jobs, tenta obter da view v_new_jobs
      if (jobData == null) {
        try {
          final newJobResponse = await _client
              .from(AppConstants.newJobsView)
              .select()
              .eq('job_id', cleanId)
              .maybeSingle();

          if (newJobResponse != null) {
            jobData = Map<String, dynamic>.from(newJobResponse);
          }
        } on PostgrestException catch (e) {
          if (!isTableOrViewUnavailable(e)) rethrow;
          debugPrint(
            '[JobRemoteDataSource.getJobById] View v_new_jobs indisponível (${e.code}). Tentando próximas...',
          );
        }
      }

      // 3. Se ainda não encontrou, tenta obter da view v_active_pipeline_jobs
      if (jobData == null) {
        try {
          final activeJobResponse = await _client
              .from(AppConstants.activePipelineJobsView)
              .select()
              .eq('job_id', cleanId)
              .maybeSingle();

          if (activeJobResponse != null) {
            jobData = Map<String, dynamic>.from(activeJobResponse);
          }
        } on PostgrestException catch (e) {
          if (!isTableOrViewUnavailable(e)) rethrow;
          debugPrint(
            '[JobRemoteDataSource.getJobById] View v_active_pipeline_jobs indisponível (${e.code}). Tentando próximas...',
          );
        }
      }

      // 4. Fallback final para v_user_jobs
      if (jobData == null) {
        try {
          dynamic userJobsBuilder = _client
              .from(AppConstants.userJobsView)
              .select()
              .eq('job_id', cleanId);

          if (effectiveUserId != null && effectiveUserId.isNotEmpty) {
            userJobsBuilder = userJobsBuilder.or(
              'user_id.is.null,user_id.eq.$effectiveUserId',
            );
          }

          final userJobResponse = await userJobsBuilder.maybeSingle();
          if (userJobResponse != null) {
            jobData = Map<String, dynamic>.from(
              userJobResponse as Map<String, dynamic>,
            );
          }
        } on PostgrestException catch (e) {
          if (!isTableOrViewUnavailable(e)) rethrow;
          debugPrint(
            '[JobRemoteDataSource.getJobById] View v_user_jobs indisponível (${e.code}).',
          );
        }
      }

      if (jobData == null) {
        throw JobNotFoundFailure(cleanId);
      }

      return JobItem.fromJson(jobData);
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
    final cleanJobId = jobId.trim();
    if (cleanJobId.isEmpty) {
      throw JobMutationFailure(
        'Identificador da vaga (job_id) não pode ser vazio para atualizar status.',
      );
    }

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
        'job_id': cleanJobId,
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
    final cleanJobId = jobId.trim();
    if (cleanJobId.isEmpty) {
      throw JobMutationFailure(
        'Identificador da vaga (job_id) não pode ser vazio para atualizar anotações.',
      );
    }
    try {
      final effectiveUserId = _resolveUserId(userId);
      final payload = <String, dynamic>{
        'job_id': cleanJobId,
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
        '[JobRemoteDataSource.updateJobNotes] PostgrestException (jobId=$cleanJobId):\n'
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
    final cleanJobId = jobId.trim();
    if (cleanJobId.isEmpty) {
      throw JobMutationFailure(
        'Identificador da vaga (job_id) não pode ser vazio para alternar arquivamento.',
      );
    }
    try {
      final effectiveUserId = _resolveUserId(userId);
      final payload = <String, dynamic>{
        'job_id': cleanJobId,
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
