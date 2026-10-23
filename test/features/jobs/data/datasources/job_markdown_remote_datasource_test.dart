import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:job_hunter_app/core/errors/job_failure.dart';
import 'package:job_hunter_app/features/jobs/data/datasources/job_markdown_remote_datasource.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  setUpAll(() {
    registerFallbackValue(Uri.parse('https://r.jina.ai/https://example.com'));
  });

  late MockHttpClient mockClient;
  late JobMarkdownRemoteDataSource dataSource;

  setUp(() {
    mockClient = MockHttpClient();
    dataSource = JobMarkdownRemoteDataSource(client: mockClient);
  });

  group('JobMarkdownRemoteDataSource', () {
    const rawJobUrl = 'https://boards.greenhouse.io/techcorp/jobs/123';
    const expectedReaderUrl = 'https://r.jina.ai/https://boards.greenhouse.io/techcorp/jobs/123';
    const sampleMarkdown = '# Senior Flutter Developer\n\nAbout the job...';

    test('fetches markdown successfully via GET to https://r.jina.ai/{url}', () async {
      when(
        () => mockClient.get(
          Uri.parse(expectedReaderUrl),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer((_) async => http.Response(sampleMarkdown, 200));

      final result = await dataSource.fetchMarkdownFromUrl(jobUrl: rawJobUrl);

      expect(result, equals(sampleMarkdown));
      verify(
        () => mockClient.get(
          Uri.parse(expectedReaderUrl),
          headers: any(named: 'headers'),
        ),
      ).called(1);
    });

    test('sends Authorization header when apiKey is supplied', () async {
      when(
        () => mockClient.get(
          Uri.parse(expectedReaderUrl),
          headers: captureAny(named: 'headers'),
        ),
      ).thenAnswer((_) async => http.Response(sampleMarkdown, 200));

      await dataSource.fetchMarkdownFromUrl(jobUrl: rawJobUrl, apiKey: 'secret-token-123');

      final captured = verify(
        () => mockClient.get(
          Uri.parse(expectedReaderUrl),
          headers: captureAny(named: 'headers'),
        ),
      ).captured.first as Map<String, String>;

      expect(captured['Authorization'], equals('Bearer secret-token-123'));
    });

    test('throws JobMarkdownInvalidUrlFailure when URL is empty', () async {
      expect(
        () => dataSource.fetchMarkdownFromUrl(jobUrl: '   '),
        throwsA(isA<JobMarkdownInvalidUrlFailure>()),
      );
    });

    test('throws JobMarkdownEmptyFailure when response body is empty or whitespace', () async {
      when(
        () => mockClient.get(
          Uri.parse(expectedReaderUrl),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer((_) async => http.Response('   ', 200));

      expect(
        () => dataSource.fetchMarkdownFromUrl(jobUrl: rawJobUrl),
        throwsA(isA<JobMarkdownEmptyFailure>()),
      );
    });

    test('throws JobMarkdownRateLimitFailure when status is 429', () async {
      when(
        () => mockClient.get(
          Uri.parse(expectedReaderUrl),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer((_) async => http.Response('Rate limit exceeded', 429));

      expect(
        () => dataSource.fetchMarkdownFromUrl(jobUrl: rawJobUrl),
        throwsA(isA<JobMarkdownRateLimitFailure>()),
      );
    });

    test('throws JobMarkdownNetworkFailure on HTTP error status', () async {
      when(
        () => mockClient.get(
          Uri.parse(expectedReaderUrl),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer((_) async => http.Response('Internal Server Error', 500));

      expect(
        () => dataSource.fetchMarkdownFromUrl(jobUrl: rawJobUrl),
        throwsA(isA<JobMarkdownNetworkFailure>()),
      );
    });

    test('throws JobMarkdownNetworkFailure on SocketException or Timeout', () async {
      when(
        () => mockClient.get(
          Uri.parse(expectedReaderUrl),
          headers: any(named: 'headers'),
        ),
      ).thenThrow(const SocketException('Failed to connect'));

      expect(
        () => dataSource.fetchMarkdownFromUrl(jobUrl: rawJobUrl),
        throwsA(isA<JobMarkdownNetworkFailure>()),
      );
    });
  });
}
