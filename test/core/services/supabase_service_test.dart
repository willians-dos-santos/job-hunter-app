import 'package:flutter_test/flutter_test.dart';
import 'package:job_hunter_app/core/errors/configuration_exception.dart';
import 'package:job_hunter_app/core/services/supabase_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

void main() {
  setUp(() {
    SupabaseService.reset();
  });

  tearDown(() {
    SupabaseService.reset();
  });

  group('SupabaseService', () {
    test('throws ConfigurationException when accessed before initialization', () {
      expect(SupabaseService.isInitialized, isFalse);
      expect(
        () => SupabaseService.client,
        throwsA(isA<ConfigurationException>()),
      );
    });

    test('throws ConfigurationException when url or anonKey are empty', () async {
      expect(
        () => SupabaseService.initialize(url: '', anonKey: 'anon-key'),
        throwsA(isA<ConfigurationException>()),
      );
      expect(
        () => SupabaseService.initialize(url: 'https://test.supabase.co', anonKey: ''),
        throwsA(isA<ConfigurationException>()),
      );
    });

    test('provides mock client when set for testing', () {
      final mock = MockSupabaseClient();
      SupabaseService.initForTest(mock);

      expect(SupabaseService.isInitialized, isTrue);
      expect(SupabaseService.client, same(mock));
    });
  });
}
