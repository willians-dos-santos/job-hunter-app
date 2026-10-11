import 'app_exception.dart';

/// Exception thrown when environment or platform configuration is missing or invalid.
class ConfigurationException extends AppException {
  const ConfigurationException(super.message, {super.code, super.details});

  /// Factory helper for missing required environment variables.
  factory ConfigurationException.missingKey(String key) {
    return ConfigurationException(
      'Variável de ambiente obrigatória "$key" não encontrada ou vazia. '
      'Por favor, configure o arquivo .env a partir do template .env.example.',
      code: 'MISSING_ENV_KEY',
      details: {'missingKey': key},
    );
  }

  /// Factory helper when .env file cannot be loaded or is absent.
  factory ConfigurationException.fileNotFound([String fileName = '.env']) {
    return ConfigurationException(
      'Arquivo de configuração "$fileName" não encontrado. '
      'Crie o arquivo "$fileName" na raiz do projeto com base no template .env.example.',
      code: 'ENV_FILE_NOT_FOUND',
      details: {'fileName': fileName},
    );
  }

  @override
  String toString() => 'ConfigurationException: $message';
}
