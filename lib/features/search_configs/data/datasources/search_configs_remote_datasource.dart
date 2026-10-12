import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/services/env_config.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/models/search_config.dart';

/// Contract for remote operations on `search_configs` table in Supabase.
abstract class SearchConfigsRemoteDataSource {
  /// Fetches all search configs from Supabase.
  Future<List<SearchConfig>> fetchConfigs({String? userId});

  /// Inserts a search config into Supabase.
  Future<void> insertConfig(SearchConfig config, {String? userId});

  /// Updates the `is_active` status of a search config.
  Future<void> updateActive(String id, bool isActive, {String? userId});

  /// Deletes a search config from Supabase.
  Future<void> removeConfig(String id, {String? userId});
}

/// Implementation of [SearchConfigsRemoteDataSource] using the Supabase client.
class SearchConfigsRemoteDataSourceImpl implements SearchConfigsRemoteDataSource {
  SearchConfigsRemoteDataSourceImpl([
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
      // Ignora erro em ambientes de teste sem auth stub
    }
    return null;
  }

  /// Resolves effective user ID according to multi-tenancy requirements.
  String? get currentUserId {
    final configured = _configuredUserId?.trim();
    if (configured != null && configured.isNotEmpty) {
      return configured;
    }
    final authId = _tryGetAuthUserId();
    if (authId != null && authId.isNotEmpty) {
      return authId;
    }
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
  Future<List<SearchConfig>> fetchConfigs({String? userId}) async {
    try {
      final effectiveUserId = _resolveUserId(userId);
      debugPrint(
        '[SearchConfigsRemoteDataSource.fetchConfigs] Fetching from ${AppConstants.searchConfigsTable} for userId=$effectiveUserId',
      );

      dynamic query = _client.from(AppConstants.searchConfigsTable).select();

      if (effectiveUserId != null && effectiveUserId.isNotEmpty) {
        query = query.eq('user_id', effectiveUserId);
      }

      query = query.order('category').order('value');

      final response = await query;
      final rawList = response is List ? response : <dynamic>[];
      final list = rawList.cast<Map<String, dynamic>>();

      return list.map(SearchConfig.fromJson).toList();
    } on PostgrestException catch (e) {
      debugPrint(
        '[SearchConfigsRemoteDataSource.fetchConfigs] PostgrestException: ${e.message}',
      );
      throw ServerException(
        'Erro ao consultar critérios de busca: ${e.message}',
        code: e.code,
        details: e.details,
      );
    } catch (e) {
      debugPrint('[SearchConfigsRemoteDataSource.fetchConfigs] Error: $e');
      if (e is AppException) rethrow;
      throw ServerException(
        'Erro inesperado ao consultar critérios de busca: $e',
        details: e,
      );
    }
  }

  @override
  Future<void> insertConfig(SearchConfig config, {String? userId}) async {
    try {
      final effectiveUserId = _resolveUserId(userId ?? config.userId);
      final payload = config.toJson();

      if (effectiveUserId != null &&
          effectiveUserId.isNotEmpty &&
          !payload.containsKey('user_id')) {
        payload['user_id'] = effectiveUserId;
      }

      // Permite que o Supabase/PostgreSQL gere o UUID caso o id seja vazio
      if (payload['id'] == null ||
          (payload['id'] is String && (payload['id'] as String).isEmpty)) {
        payload.remove('id');
      }

      debugPrint(
        '[SearchConfigsRemoteDataSource.insertConfig] Inserting payload to ${AppConstants.searchConfigsTable}: $payload',
      );

      await _client.from(AppConstants.searchConfigsTable).insert(payload);
    } on PostgrestException catch (e) {
      debugPrint(
        '[SearchConfigsRemoteDataSource.insertConfig] PostgrestException: ${e.message}',
      );
      throw ServerException(
        'Erro ao cadastrar critério de busca: ${e.message}',
        code: e.code,
        details: e.details,
      );
    } catch (e) {
      debugPrint('[SearchConfigsRemoteDataSource.insertConfig] Error: $e');
      if (e is AppException) rethrow;
      throw ServerException(
        'Erro inesperado ao cadastrar critério: $e',
        details: e,
      );
    }
  }

  @override
  Future<void> updateActive(String id, bool isActive, {String? userId}) async {
    try {
      final effectiveUserId = _resolveUserId(userId);
      debugPrint(
        '[SearchConfigsRemoteDataSource.updateActive] Updating id=$id to isActive=$isActive, userId=$effectiveUserId',
      );

      dynamic builder = _client
          .from(AppConstants.searchConfigsTable)
          .update({'is_active': isActive})
          .eq('id', id);

      if (effectiveUserId != null && effectiveUserId.isNotEmpty) {
        builder = builder.eq('user_id', effectiveUserId);
      }

      await builder;
    } on PostgrestException catch (e) {
      debugPrint(
        '[SearchConfigsRemoteDataSource.updateActive] PostgrestException: ${e.message}',
      );
      throw ServerException(
        'Erro ao atualizar status do critério: ${e.message}',
        code: e.code,
        details: e.details,
      );
    } catch (e) {
      debugPrint('[SearchConfigsRemoteDataSource.updateActive] Error: $e');
      if (e is AppException) rethrow;
      throw ServerException(
        'Erro inesperado ao atualizar status: $e',
        details: e,
      );
    }
  }

  @override
  Future<void> removeConfig(String id, {String? userId}) async {
    try {
      final effectiveUserId = _resolveUserId(userId);
      debugPrint(
        '[SearchConfigsRemoteDataSource.removeConfig] Deleting id=$id, userId=$effectiveUserId',
      );

      dynamic builder = _client
          .from(AppConstants.searchConfigsTable)
          .delete()
          .eq('id', id);

      if (effectiveUserId != null && effectiveUserId.isNotEmpty) {
        builder = builder.eq('user_id', effectiveUserId);
      }

      await builder;
    } on PostgrestException catch (e) {
      debugPrint(
        '[SearchConfigsRemoteDataSource.removeConfig] PostgrestException: ${e.message}',
      );
      throw ServerException(
        'Erro ao remover critério de busca: ${e.message}',
        code: e.code,
        details: e.details,
      );
    } catch (e) {
      debugPrint('[SearchConfigsRemoteDataSource.removeConfig] Error: $e');
      if (e is AppException) rethrow;
      throw ServerException(
        'Erro inesperado ao remover critério: $e',
        details: e,
      );
    }
  }
}
