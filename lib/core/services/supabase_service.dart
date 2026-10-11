import 'package:supabase_flutter/supabase_flutter.dart';

import '../errors/configuration_exception.dart';

/// Wrapper service for Supabase initialization and client access.
class SupabaseService {
  SupabaseService._();

  static Supabase? _instance;
  static SupabaseClient? _mockClient;

  /// Whether the Supabase client is currently initialized.
  static bool get isInitialized => _instance != null || _mockClient != null;

  /// Initializes the Supabase singleton using the provided [url] and [anonKey].
  static Future<Supabase> initialize({
    required String url,
    required String anonKey,
  }) async {
    if (url.trim().isEmpty) {
      throw const ConfigurationException(
        'Supabase URL não pode ser vazia.',
      );
    }
    if (anonKey.trim().isEmpty) {
      throw const ConfigurationException(
        'Supabase Anon Key não pode ser vazia.',
      );
    }

    final instance = await Supabase.initialize(
      url: url.trim(),
      publishableKey: anonKey.trim(),
    );
    _instance = instance;
    return instance;
  }

  /// Sets an in-memory client for testing purposes.
  static void initForTest(SupabaseClient client) {
    _mockClient = client;
  }

  /// Returns the global [SupabaseClient].
  ///
  /// Throws [ConfigurationException] if accessed prior to initialization.
  static SupabaseClient get client {
    if (_mockClient != null) {
      return _mockClient!;
    }
    if (_instance == null) {
      throw const ConfigurationException(
        'SupabaseService não foi inicializado. '
        'Certifique-se de chamar `SupabaseService.initialize()` antes de acessar o cliente.',
      );
    }
    return _instance!.client;
  }

  /// Resets the service instance (primarily for test teardown).
  static void reset() {
    _instance = null;
    _mockClient = null;
  }
}
