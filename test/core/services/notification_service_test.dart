import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:job_hunter_app/core/constants/app_constants.dart';
import 'package:job_hunter_app/core/services/notification_service.dart';
import 'package:job_hunter_app/features/jobs/domain/models/job_item.dart';
import 'package:job_hunter_app/features/jobs/domain/models/job_status.dart';
import 'package:job_hunter_app/features/jobs/domain/repositories/job_repository.dart';
import 'package:job_hunter_app/features/jobs/presentation/cubit/jobs_cubit.dart';
import 'package:job_hunter_app/features/jobs/presentation/widgets/job_details_modal.dart';

import '../../features/jobs/data/helpers/supabase_test_fakes.dart';

class MockFirebaseMessaging extends Mock implements FirebaseMessaging {}

class MockFlutterLocalNotificationsPlugin extends Mock
    implements FlutterLocalNotificationsPlugin {}

class MockJobsRepository extends Mock implements IJobRepository {}

class MockJobsCubit extends Mock implements JobsCubit {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockFirebaseMessaging mockMessaging;
  late MockFlutterLocalNotificationsPlugin mockLocalNotifications;
  late MockSupabaseClient mockSupabaseClient;
  late MockSupabaseQueryBuilder mockQueryBuilder;
  late MockJobsRepository mockJobRepository;
  late GlobalKey<NavigatorState> testNavKey;

  setUpAll(() {
    registerFallbackValue(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    registerFallbackValue(
      const AndroidNotificationChannel('id', 'name'),
    );
    registerFallbackValue(
      const NotificationDetails(),
    );
    registerFallbackValue(
      const JobItem(
        jobId: 'fallback',
        title: 'fallback',
        companyName: 'fallback',
        platform: 'fallback',
        jobUrl: 'fallback',
        status: JobStatus.newJob,
      ),
    );
  });

  setUp(() {
    mockMessaging = MockFirebaseMessaging();
    mockLocalNotifications = MockFlutterLocalNotificationsPlugin();
    mockSupabaseClient = MockSupabaseClient();
    mockQueryBuilder = MockSupabaseQueryBuilder();
    mockJobRepository = MockJobsRepository();
    testNavKey = GlobalKey<NavigatorState>();

    when(() => mockSupabaseClient.from(any()))
        .thenAnswer((_) => mockQueryBuilder);

    NotificationService.initForTest(
      messaging: mockMessaging,
      localNotifications: mockLocalNotifications,
      supabaseClient: mockSupabaseClient,
      jobRepository: mockJobRepository,
      navKey: testNavKey,
    );
  });

  tearDown(() {
    NotificationService.reset();
  });

  group('NotificationService - Payload Extraction', () {
    test('extracts job_id from map with job_id key', () {
      final id = NotificationService.extractJobId({'job_id': 'job-123'});
      expect(id, 'job-123');
    });

    test('extracts job_id from map with jobId key (camelCase)', () {
      final id = NotificationService.extractJobId({'jobId': 'job-456'});
      expect(id, 'job-456');
    });

    test('extracts job_id from JSON string with job_id', () {
      final jsonStr = jsonEncode({'job_id': 'job-789', 'title': 'Engenheiro'});
      final id = NotificationService.extractJobId(jsonStr);
      expect(id, 'job-789');
    });

    test('extracts job_id from JSON string with jobId', () {
      final jsonStr = jsonEncode({'jobId': 'job-abc'});
      final id = NotificationService.extractJobId(jsonStr);
      expect(id, 'job-abc');
    });

    test('extracts raw string when not JSON formatted', () {
      final id = NotificationService.extractJobId('plain-job-id');
      expect(id, 'plain-job-id');
    });

    test('returns null when payload is empty or does not contain job id', () {
      expect(NotificationService.extractJobId(null), isNull);
      expect(NotificationService.extractJobId(''), isNull);
      expect(NotificationService.extractJobId(<String, dynamic>{}), isNull);
      expect(NotificationService.extractJobId('   '), isNull);
    });
  });

  group('NotificationService - Token Synchronization with Supabase', () {
    test(
        'upserts device token to public.user_device_tokens with onConflict: user_id,fcm_token',
        () async {
      Map<String, dynamic>? capturedPayload;
      String? capturedOnConflict;

      when(() => mockQueryBuilder.upsert(
            any(),
            onConflict: any(named: 'onConflict'),
          )).thenAnswer((invocation) {
        capturedPayload =
            invocation.positionalArguments[0] as Map<String, dynamic>?;
        capturedOnConflict =
            invocation.namedArguments[const Symbol('onConflict')] as String?;
        return FakePostgrestFilterBuilder<void>();
      });

      await NotificationService.instance.syncDeviceToken(
        userId: 'user-xyz',
        tokenOverride: 'mock-fcm-token-123',
        client: mockSupabaseClient,
      );

      verify(() => mockSupabaseClient.from(AppConstants.userDeviceTokensTable))
          .called(1);
      expect(capturedPayload, isNotNull);
      expect(capturedPayload!['user_id'], 'user-xyz');
      expect(capturedPayload!['fcm_token'], 'mock-fcm-token-123');
      expect(capturedPayload!['updated_at'], isNotNull);
      expect(capturedOnConflict, 'user_id,fcm_token');
    });

    test('uses fallback without updated_at when PostgrestException mentions updated_at',
        () async {
      var callCount = 0;
      Map<String, dynamic>? fallbackPayload;

      when(() => mockQueryBuilder.upsert(
            any(),
            onConflict: any(named: 'onConflict'),
          )).thenAnswer((invocation) {
        callCount++;
        if (callCount == 1) {
          throw const PostgrestException(
            message: "Could not find the 'updated_at' column in the schema cache",
            code: 'PGRST204',
          );
        }
        fallbackPayload =
            invocation.positionalArguments[0] as Map<String, dynamic>?;
        return FakePostgrestFilterBuilder<void>();
      });

      await NotificationService.instance.syncDeviceToken(
        userId: 'user-xyz',
        tokenOverride: 'token-abc',
        client: mockSupabaseClient,
      );

      expect(callCount, 2);
      expect(fallbackPayload, isNotNull);
      expect(fallbackPayload!['user_id'], 'user-xyz');
      expect(fallbackPayload!['fcm_token'], 'token-abc');
      expect(fallbackPayload!.containsKey('updated_at'), isFalse);
    });

    test('skips upsert when userId is missing', () async {
      await NotificationService.instance.syncDeviceToken(
        userId: '',
        tokenOverride: 'valid-token',
        client: mockSupabaseClient,
      );

      verifyNever(() => mockSupabaseClient.from(any()));
    });

    test('skips upsert when token is null or empty', () async {
      when(() => mockMessaging.getToken()).thenAnswer((_) async => null);

      await NotificationService.instance.syncDeviceToken(
        userId: 'valid-user',
        tokenOverride: null,
        client: mockSupabaseClient,
      );

      verifyNever(() => mockSupabaseClient.from(any()));
    });
  });

  group('NotificationService - Foreground Notification Banner', () {
    test('shows local notification with title, body, and payload containing data',
        () async {
      when(() => mockLocalNotifications.show(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            notificationDetails: any(named: 'notificationDetails'),
            payload: any(named: 'payload'),
          )).thenAnswer((_) async {});

      final message = RemoteMessage(
        messageId: 'msg_001',
        notification: const RemoteNotification(
          title: 'Nova Vaga Flutter',
          body: 'Uma vaga compatível com seu perfil foi encontrada!',
        ),
        data: {'job_id': 'job-flutter-99'},
      );

      await NotificationService.instance.showForegroundNotification(message);

      verify(() => mockLocalNotifications.show(
            id: any(named: 'id'),
            title: 'Nova Vaga Flutter',
            body: 'Uma vaga compatível com seu perfil foi encontrada!',
            notificationDetails: any(named: 'notificationDetails'),
            payload: any(named: 'payload', that: contains('job-flutter-99')),
          )).called(1);
    });
  });

  group('NotificationService - Navigation to Job Details', () {
    const testJob = JobItem(
      jobId: 'job-target-1',
      title: 'Senior Flutter Developer',
      companyName: 'Tech Corp',
      platform: 'greenhouse',
      jobUrl: 'https://techcorp.com/jobs/1',
      status: JobStatus.newJob,
      notes: 'Nota existente',
    );

    testWidgets('opens JobDetailsModal when job is found remotely',
        (tester) async {
      when(() => mockJobRepository.getJobById('job-target-1'))
          .thenAnswer((_) async => testJob);

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: testNavKey,
          home: const Scaffold(body: Text('Home Kanban')),
        ),
      );
      await tester.pumpAndSettle();

      await NotificationService.instance.navigateToJobDetails('job-target-1');
      await tester.pumpAndSettle();

      expect(find.byType(JobDetailsModal), findsOneWidget);
      expect(find.text('Senior Flutter Developer'), findsOneWidget);
      expect(find.text('Tech Corp'), findsOneWidget);
    });

    testWidgets('stores pendingJobId when navigator is not yet mounted and resolves on checkPendingNotification',
        (tester) async {
      when(() => mockJobRepository.getJobById('job-target-1'))
          .thenAnswer((_) async => testJob);

      // Navigator not mounted yet
      await NotificationService.instance.navigateToJobDetails('job-target-1');
      expect(NotificationService.instance.pendingJobId, 'job-target-1');

      // Now mount the app
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: testNavKey,
          home: const Scaffold(body: Text('Home Kanban')),
        ),
      );
      await tester.pumpAndSettle();

      // Trigger check pending notification
      await NotificationService.instance.checkPendingNotification();
      await tester.pumpAndSettle();

      expect(NotificationService.instance.pendingJobId, isNull);
      expect(find.byType(JobDetailsModal), findsOneWidget);
    });

    testWidgets('shows floating SnackBar when job cannot be retrieved',
        (tester) async {
      when(() => mockJobRepository.getJobById('invalid-job-id'))
          .thenThrow(Exception('Vaga inexistente no banco'));

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: testNavKey,
          home: const Scaffold(body: Text('Home Kanban')),
        ),
      );
      await tester.pumpAndSettle();

      await NotificationService.instance.navigateToJobDetails('invalid-job-id');
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('invalid-job-id'), findsOneWidget);
    });
  });

  group('Background Handler', () {
    test('executes top-level firebaseMessagingBackgroundHandler gracefully',
        () async {
      final message = RemoteMessage(
        messageId: 'bg_001',
        data: {'job_id': 'bg-job-1'},
      );

      // Should complete without uncaught errors
      await expectLater(
        firebaseMessagingBackgroundHandler(message),
        completes,
      );
    });
  });
}
