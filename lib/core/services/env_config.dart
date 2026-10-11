import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../constants/env_constants.dart';
import '../errors/configuration_exception.dart';

/// Service responsible for loading and providing environment variables securely.
class EnvConfig {
  EnvConfig._();

  static bool _initialized = false;

  /// Whether the environment configuration has been loaded.
  static bool get isInitialized => _initialized;

  /// Initializes the environment configuration by loading the specified `.env` file.
  ///
  /// Throws [ConfigurationException] if the file cannot be loaded or if
  /// required variables (`SUPABASE_URL`, `SUPABASE_ANON_KEY`) are missing or empty.
  static Future<void> init({
    String fileName = '.env',
    DotEnv? customDotEnv,
  }) async {
    final env = customDotEnv ?? dotenv;

    try {
      await env.load(fileName: fileName);
    } catch (e) {
      if (e is ConfigurationException) {
        rethrow;
      }
      throw ConfigurationException(
        'Falha ao carregar o arquivo de ambiente "$fileName": $e. '
        'Certifique-se de que o arquivo .env existe e segue o template .env.example.',
        details: e,
      );
    }

    _validateRequiredKeys(env);
    _initialized = true;
  }

  /// Initializes environment with an in-memory map (useful for automated testing).
  static void initForTest(Map<String, String> values) {
    final buffer = StringBuffer();
    for (final entry in values.entries) {
      buffer.writeln('${entry.key}=${entry.value}');
    }
    dotenv.loadFromString(envString: buffer.toString());
    _validateRequiredKeys(dotenv);
    _initialized = true;
  }

  static void _validateRequiredKeys(DotEnv env) {
    final url = env.maybeGet(EnvConstants.supabaseUrl)?.trim();
    if (url == null || url.isEmpty) {
      throw ConfigurationException.missingKey(EnvConstants.supabaseUrl);
    }

    final anonKey = env.maybeGet(EnvConstants.supabaseAnonKey)?.trim();
    if (anonKey == null || anonKey.isEmpty) {
      throw ConfigurationException.missingKey(EnvConstants.supabaseAnonKey);
    }
  }

  /// Supabase project URL.
  static String get supabaseUrl {
    _ensureInitialized();
    final url = dotenv.maybeGet(EnvConstants.supabaseUrl);
    if (url == null || url.trim().isEmpty) {
      throw ConfigurationException.missingKey(EnvConstants.supabaseUrl);
    }
    return url.trim();
  }

  /// Supabase public anon key.
  static String get supabaseAnonKey {
    _ensureInitialized();
    final key = dotenv.maybeGet(EnvConstants.supabaseAnonKey);
    if (key == null || key.trim().isEmpty) {
      throw ConfigurationException.missingKey(EnvConstants.supabaseAnonKey);
    }
    return key.trim();
  }

  /// Retrieves an optional environment variable by [key], returning [defaultValue] if absent.
  static String? get(String key, {String? defaultValue}) {
    _ensureInitialized();
    return dotenv.maybeGet(key) ?? defaultValue;
  }

  static void _ensureInitialized() {
    if (!_initialized) {
      throw const ConfigurationException(
        'EnvConfig não foi inicializado. '
        'Chame `await EnvConfig.init()` antes de acessar as configurações.',
      );
    }
  }

  /// Resets initialization state (primarily for test teardown).
  static void reset() {
    _initialized = false;
    dotenv.clean();
  }
}
