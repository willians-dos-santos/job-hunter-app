import 'dart:async';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../../../../core/errors/job_failure.dart';
import '../../domain/repositories/job_markdown_repository.dart';

/// Remote HTTP data source communicating with Jina AI Reader (https://r.jina.ai/).
class JobMarkdownRemoteDataSource implements IJobMarkdownRemoteDataSource {
  JobMarkdownRemoteDataSource({
    http.Client? client,
    this.timeout = const Duration(seconds: 20),
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final Duration timeout;

  static const String _readerBaseUrl = 'https://r.jina.ai/';

  String _sanitizeUrl(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return '';
    final lower = trimmed.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return trimmed;
    }
    return 'https://$trimmed';
  }

  @override
  Future<String> fetchMarkdownFromUrl({
    required String jobUrl,
    String? apiKey,
  }) async {
    final sanitizedTarget = _sanitizeUrl(jobUrl);
    if (sanitizedTarget.isEmpty) {
      throw const JobMarkdownInvalidUrlFailure('URL da vaga vazia ou inválida.');
    }

    String? envApiKey;
    try {
      if (dotenv.isInitialized) {
        envApiKey = dotenv.env['JINA_API_KEY'];
      }
    } catch (_) {
      envApiKey = null;
    }
    final effectiveApiKey = apiKey ?? envApiKey;
    final requestUri = Uri.parse('$_readerBaseUrl$sanitizedTarget');

    final headers = <String, String>{
      'Accept': 'text/plain',
      'User-Agent': 'JobHunterApp/1.0',
      if (effectiveApiKey != null && effectiveApiKey.trim().isNotEmpty)
        'Authorization': 'Bearer ${effectiveApiKey.trim()}',
    };

    try {
      final response = await _client.get(
        requestUri,
        headers: headers,
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final body = response.body.trim();
        if (body.isEmpty) {
          throw const JobMarkdownEmptyFailure(
            'A página da vaga retornou conteúdo vazio ou exigiu verificação anti-bot.',
          );
        }
        return body;
      }

      if (response.statusCode == 429) {
        throw const JobMarkdownRateLimitFailure(
          'Limite de requisições excedido no leitor. Aguarde um instante ou forneça uma chave JINA_API_KEY.',
        );
      }

      if (response.statusCode == 400) {
        throw JobMarkdownInvalidUrlFailure(
          'URL da vaga rejeitada pelo leitor: ${response.body}',
        );
      }

      throw JobMarkdownNetworkFailure(
        'Falha ao converter página: HTTP ${response.statusCode}',
        details: response.body,
      );
    } on JobMarkdownFailure {
      rethrow;
    } on TimeoutException catch (e) {
      throw JobMarkdownNetworkFailure(
        'Tempo limite de 20s esgotado ao tentar converter a página da vaga.',
        details: e,
      );
    } on SocketException catch (e) {
      throw JobMarkdownNetworkFailure(
        'Sem conexão com a internet ou servidor inacessível.',
        details: e,
      );
    } on http.ClientException catch (e) {
      throw JobMarkdownNetworkFailure(
        'Erro na comunicação HTTP com o leitor: ${e.message}',
        details: e,
      );
    } catch (e) {
      throw JobMarkdownNetworkFailure(
        'Erro inesperado durante a conversão da vaga: $e',
        details: e,
      );
    }
  }
}
