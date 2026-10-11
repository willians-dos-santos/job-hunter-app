import 'package:flutter_test/flutter_test.dart';
import 'package:job_hunter_app/core/constants/env_constants.dart';
import 'package:job_hunter_app/core/errors/configuration_exception.dart';
import 'package:job_hunter_app/core/services/env_config.dart';

void main() {
  setUp(() {
    EnvConfig.reset();
  });

  tearDown(() {
    EnvConfig.reset();
  });

  group('EnvConfig', () {
    test('throws ConfigurationException when accessed before initialization', () {
      expect(
        () => EnvConfig.supabaseUrl,
        throwsA(isA<ConfigurationException>()),
      );
      expect(
        () => EnvConfig.supabaseAnonKey,
        throwsA(isA<ConfigurationException>()),
      );
    });

    test('initializes successfully with valid test variables', () {
      EnvConfig.initForTest({
        EnvConstants.supabaseUrl: 'https://test-project.supabase.co',
        EnvConstants.supabaseAnonKey: 'valid-test-anon-key-12345',
      });

      expect(EnvConfig.isInitialized, isTrue);
      expect(EnvConfig.supabaseUrl, 'https://test-project.supabase.co');
      expect(EnvConfig.supabaseAnonKey, 'valid-test-anon-key-12345');
    });

    test('throws ConfigurationException when SUPABASE_URL is missing', () {
      expect(
        () => EnvConfig.initForTest({
          EnvConstants.supabaseAnonKey: 'valid-key',
        }),
        throwsA(
          isA<ConfigurationException>().having(
            (e) => e.message,
            'message',
            contains(EnvConstants.supabaseUrl),
          ),
        ),
      );
    });

    test('throws ConfigurationException when SUPABASE_ANON_KEY is missing or empty', () {
      expect(
        () => EnvConfig.initForTest({
          EnvConstants.supabaseUrl: 'https://test.supabase.co',
          EnvConstants.supabaseAnonKey: '   ',
        }),
        throwsA(
          isA<ConfigurationException>().having(
            (e) => e.message,
            'message',
            contains(EnvConstants.supabaseAnonKey),
          ),
        ),
      );
    });

    test('retrieves custom variables with default fallback', () {
      EnvConfig.initForTest({
        EnvConstants.supabaseUrl: 'https://test.supabase.co',
        EnvConstants.supabaseAnonKey: 'anon-key',
        'CUSTOM_VAR': 'hello',
      });

      expect(EnvConfig.get('CUSTOM_VAR'), 'hello');
      expect(EnvConfig.get('NON_EXISTENT', defaultValue: 'fallback'), 'fallback');
    });
  });
}
