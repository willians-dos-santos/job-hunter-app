import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/jobs/data/repositories/job_repository_impl.dart';
import '../../features/jobs/domain/models/job_item.dart';
import '../../features/jobs/domain/repositories/job_repository.dart';
import '../../features/jobs/presentation/cubit/jobs_cubit.dart';
import '../../features/jobs/presentation/cubit/jobs_state.dart';
import '../../features/jobs/presentation/widgets/job_details_modal.dart';
import '../../firebase_options.dart';
import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import 'env_config.dart';
import 'supabase_service.dart';

/// Top-level background message handler required by Firebase Cloud Messaging.
///
/// Must be annotated with [pragma('vm:entry-point')] so it survives tree shaking
/// when invoked in background isolates.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('[NotificationService] Background Firebase init warning: $e');
  }
  debugPrint(
    '[NotificationService] Background message received: ${message.messageId}, data: ${message.data}',
  );
}

/// Service managing Push Notifications via Firebase Cloud Messaging (FCM)
/// and local foreground banners via Flutter Local Notifications.
class NotificationService {
  NotificationService._({
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotifications,
    SupabaseClient? supabaseClient,
    IJobRepository? jobRepository,
    GlobalKey<NavigatorState>? navKey,
  })  : _messaging = messaging,
        _localNotifications = localNotifications,
        _supabaseClient = supabaseClient,
        _jobRepository = jobRepository,
        _navigatorKey = navKey;

  /// Global singleton instance.
  static NotificationService instance = NotificationService._();

  /// Default navigation key for root application routing.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  final FirebaseMessaging? _messaging;
  final FlutterLocalNotificationsPlugin? _localNotifications;
  final SupabaseClient? _supabaseClient;
  final IJobRepository? _jobRepository;
  final GlobalKey<NavigatorState>? _navigatorKey;

  bool _isInitialized = false;
  String? _pendingJobId;
  StreamSubscription<AuthState>? _authSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;

  /// Whether the notification service has been initialized.
  bool get isInitialized => _isInitialized;

  /// Pending job ID awaiting navigation when the navigator was not yet mounted.
  String? get pendingJobId => _pendingJobId;

  /// Resolves the active [FirebaseMessaging] instance.
  FirebaseMessaging get messagingInstance =>
      _messaging ?? FirebaseMessaging.instance;

  /// Resolves the active [FlutterLocalNotificationsPlugin] instance.
  FlutterLocalNotificationsPlugin get localNotificationsPlugin =>
      _localNotifications ?? FlutterLocalNotificationsPlugin();

  /// Resolves the active [SupabaseClient].
  SupabaseClient _resolveClient() {
    if (_supabaseClient != null) return _supabaseClient;
    return SupabaseService.client;
  }

  /// Resolves the effective navigation key.
  GlobalKey<NavigatorState> get effectiveNavigatorKey =>
      _navigatorKey ?? navigatorKey;

  /// Initializes Firebase, background handlers, foreground listeners,
  /// local notifications, and device token synchronization.
  Future<void> initialize({bool requestPermissions = true}) async {
    // 1. Firebase Core Initialization
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('[NotificationService] Firebase Core inicializado com sucesso.');
    } catch (e) {
      debugPrint('[NotificationService] Aviso na inicialização do Firebase: $e');
    }

    // 2. Background handler registration
    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    } catch (e) {
      debugPrint('[NotificationService] Aviso ao registrar background handler: $e');
    }

    // 3. Local notifications setup for foreground messages
    try {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      );

      await localNotificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          _handleLocalNotificationTap(response);
        },
      );

      // Create Android Notification Channel
      const androidChannel = AndroidNotificationChannel(
        AppConstants.notificationChannelId,
        AppConstants.notificationChannelName,
        description: 'Notificações de novas vagas e atualizações do Job Hunter',
        importance: Importance.max,
      );
      await localNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);
    } catch (e) {
      debugPrint('[NotificationService] Aviso na configuração de notificações locais: $e');
    }

    // 4. Request notification permissions
    if (requestPermissions) {
      try {
        await messagingInstance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );
        await messagingInstance.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
        await localNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      } catch (e) {
        debugPrint('[NotificationService] Aviso ao solicitar permissões: $e');
      }
    }

    // 5. Handle foreground messages with local notification banner
    try {
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint(
          '[NotificationService] Mensagem em primeiro plano: ${message.messageId}, data: ${message.data}',
        );
        showForegroundNotification(message);
      });
    } catch (e) {
      debugPrint('[NotificationService] Aviso ao escutar onMessage: $e');
    }

    // 6. Handle notification click when app is in background
    try {
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint(
          '[NotificationService] Notificação tocada em background: ${message.data}',
        );
        _handleRemoteMessageTap(message);
      });
    } catch (e) {
      debugPrint('[NotificationService] Aviso ao escutar onMessageOpenedApp: $e');
    }

    // 7. Handle notification click when app was terminated
    try {
      final initialMessage = await messagingInstance.getInitialMessage();
      if (initialMessage != null) {
        debugPrint(
          '[NotificationService] App aberto a partir de notificação encerrada: ${initialMessage.data}',
        );
        _handleRemoteMessageTap(initialMessage);
      }
    } catch (e) {
      debugPrint('[NotificationService] Aviso ao checar getInitialMessage: $e');
    }

    // 8. Device Token Capture & Supabase Sync
    await syncCurrentDeviceToken();

    // Listen to Supabase Auth State changes to capture & upsert token on login
    _authSubscription?.cancel();
    try {
      final client = _resolveClient();
      _authSubscription = client.auth.onAuthStateChange.listen((data) async {
        final sessionUser = data.session?.user;
        if (sessionUser != null && sessionUser.id.isNotEmpty) {
          debugPrint(
            '[NotificationService] Evento de autenticação detectado (${data.event}). Sincronizando token.',
          );
          await syncDeviceToken(userId: sessionUser.id);
        }
      });
    } catch (e) {
      debugPrint('[NotificationService] Aviso ao registrar onAuthStateChange: $e');
    }

    // Listen to FCM token refresh
    _tokenRefreshSubscription?.cancel();
    try {
      _tokenRefreshSubscription =
          messagingInstance.onTokenRefresh.listen((newToken) async {
        debugPrint('[NotificationService] Token FCM atualizado: $newToken');
        await syncDeviceToken(tokenOverride: newToken);
      });
    } catch (e) {
      debugPrint('[NotificationService] Aviso ao registrar onTokenRefresh: $e');
    }

    _isInitialized = true;
  }

  /// Displays a local heads-up notification banner when a push arrives in foreground.
  Future<void> showForegroundNotification(RemoteMessage message) async {
    try {
      final notification = message.notification;
      final title = notification?.title ??
          message.data['title']?.toString() ??
          AppConstants.appName;
      final body = notification?.body ??
          message.data['body']?.toString() ??
          'Você tem uma nova notificação de vaga.';

      const androidDetails = AndroidNotificationDetails(
        AppConstants.notificationChannelId,
        AppConstants.notificationChannelName,
        channelDescription:
            'Notificações de novas vagas e atualizações do Job Hunter',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      );

      final payload = jsonEncode(message.data);
      final id = message.messageId.hashCode;

      await localNotificationsPlugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('[NotificationService] Erro ao exibir notificação local: $e');
    }
  }

  /// Extracts `job_id` from various payload structures (Map or JSON string).
  static String? extractJobId(dynamic source) {
    if (source == null) return null;
    if (source is Map) {
      final jobId = source['job_id'] ?? source['jobId'];
      if (jobId != null && jobId.toString().trim().isNotEmpty) {
        return jobId.toString().trim();
      }
    }
    if (source is String) {
      final str = source.trim();
      if (str.isEmpty) return null;
      try {
        final decoded = jsonDecode(str);
        if (decoded is Map) {
          final jobId = decoded['job_id'] ?? decoded['jobId'];
          if (jobId != null && jobId.toString().trim().isNotEmpty) {
            return jobId.toString().trim();
          }
        }
      } catch (_) {
        // String pode ser o próprio jobId
        return str;
      }
    }
    return null;
  }

  void _handleLocalNotificationTap(NotificationResponse response) {
    final jobId = extractJobId(response.payload);
    if (jobId != null) {
      navigateToJobDetails(jobId);
    }
  }

  void _handleRemoteMessageTap(RemoteMessage message) {
    final jobId = extractJobId(message.data);
    if (jobId != null) {
      navigateToJobDetails(jobId);
    }
  }

  /// Navigates to the Kanban board and opens the [JobDetailsModal] for [jobId].
  Future<void> navigateToJobDetails(String jobId) async {
    final context = effectiveNavigatorKey.currentContext;
    if (context == null || !context.mounted) {
      _pendingJobId = jobId;
      debugPrint(
        '[NotificationService] Contexto de navegação indisponível. jobId pendente: $jobId',
      );
      return;
    }

    try {
      // Retorna para o topo da navegação (Kanban) se alguma tela estiver sobreposta
      Navigator.of(context).popUntil((route) => route.isFirst);

      // 1. Tenta localizar a vaga já em memória no JobsCubit
      JobItem? job;
      JobsCubit? cubit;
      try {
        cubit = context.read<JobsCubit>();
        if (cubit.state is JobsLoaded) {
          final loaded = cubit.state as JobsLoaded;
          job = loaded.allJobs.where((j) => j.jobId == jobId).firstOrNull;
        }
      } catch (_) {}

      // 2. Se não estiver em memória, busca remotamente no repositório
      if (job == null) {
        final repo = _jobRepository ?? JobRepository();
        job = await repo.getJobById(jobId);
      }

      if (context.mounted) {
        unawaited(
          showJobDetailsModal(
            context,
            job: job,
            cubit: cubit,
          ),
        );
      }
    } catch (e) {
      debugPrint('[NotificationService] Erro ao abrir detalhes da vaga $jobId: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vaga #$jobId não foi encontrada: $e'),
            backgroundColor: AppColors.kanbanRejected,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Processes any pending job navigation that was requested before the navigator mounted.
  Future<void> checkPendingNotification([BuildContext? context]) async {
    if (_pendingJobId != null) {
      final pending = _pendingJobId!;
      _pendingJobId = null;
      final ctx = context ?? effectiveNavigatorKey.currentContext;
      if (ctx != null && ctx.mounted) {
        await navigateToJobDetails(pending);
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          navigateToJobDetails(pending);
        });
      }
    }
  }

  /// Captures the FCM device token and synchronizes it with Supabase if a user is resolved.
  Future<void> syncCurrentDeviceToken() async {
    final userId = _resolveUserId();
    if (userId != null && userId.isNotEmpty) {
      await syncDeviceToken(userId: userId);
    } else {
      debugPrint(
        '[NotificationService] Usuário ainda não identificado para registro de token FCM.',
      );
    }
  }

  /// Upserts the device FCM token into `public.user_device_tokens` table in Supabase.
  Future<void> syncDeviceToken({
    String? userId,
    String? tokenOverride,
    SupabaseClient? client,
  }) async {
    try {
      final effectiveUserId = userId ?? _resolveUserId();
      if (effectiveUserId == null || effectiveUserId.isEmpty) {
        debugPrint(
          '[NotificationService] syncDeviceToken: Nenhum usuário autenticado.',
        );
        return;
      }

      final token = tokenOverride ?? await _getToken();
      if (token == null || token.trim().isEmpty) {
        debugPrint(
          '[NotificationService] syncDeviceToken: Token FCM não obtido.',
        );
        return;
      }

      final supabase = client ?? _resolveClient();
      final cleanUserId = effectiveUserId.trim();
      final cleanToken = token.trim();

      debugPrint(
        '[NotificationService] Registrando token FCM para user_id=$cleanUserId em ${AppConstants.userDeviceTokensTable}',
      );

      final payload = <String, dynamic>{
        'user_id': cleanUserId,
        'fcm_token': cleanToken,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      try {
        await supabase
            .from(AppConstants.userDeviceTokensTable)
            .upsert(payload, onConflict: 'user_id,fcm_token');
        debugPrint(
          '[NotificationService] Token FCM registrado com sucesso no Supabase.',
        );
      } on PostgrestException catch (e) {
        // Fallback caso a coluna updated_at não exista na tabela física
        if (e.message.contains('updated_at') ||
            (e.details?.toString().contains('updated_at') ?? false)) {
          final payloadFallback = <String, dynamic>{
            'user_id': cleanUserId,
            'fcm_token': cleanToken,
          };
          await supabase
              .from(AppConstants.userDeviceTokensTable)
              .upsert(payloadFallback, onConflict: 'user_id,fcm_token');
          debugPrint(
            '[NotificationService] Token FCM registrado via fallback sem updated_at.',
          );
        } else {
          rethrow;
        }
      }
    } catch (e) {
      debugPrint('[NotificationService] Erro ao sincronizar token FCM: $e');
    }
  }

  Future<String?> _getToken() async {
    try {
      return await messagingInstance.getToken();
    } catch (e) {
      debugPrint('[NotificationService] Falha ao obter token via getToken(): $e');
      return null;
    }
  }

  String? _resolveUserId() {
    try {
      final authUser = _resolveClient().auth.currentUser?.id.trim();
      if (authUser != null && authUser.isNotEmpty) {
        return authUser;
      }
    } catch (_) {}

    if (EnvConfig.isInitialized) {
      final envId = EnvConfig.supabaseUserId?.trim();
      if (envId != null && envId.isNotEmpty) {
        return envId;
      }
    }
    return null;
  }

  /// Cancels subscriptions and clears pending states.
  void dispose() {
    _authSubscription?.cancel();
    _tokenRefreshSubscription?.cancel();
    _pendingJobId = null;
    _isInitialized = false;
  }

  /// Sets up a test instance with mock dependencies.
  static void initForTest({
    NotificationService? service,
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotifications,
    SupabaseClient? supabaseClient,
    IJobRepository? jobRepository,
    GlobalKey<NavigatorState>? navKey,
  }) {
    instance.dispose();
    instance = service ??
        NotificationService._(
          messaging: messaging,
          localNotifications: localNotifications,
          supabaseClient: supabaseClient,
          jobRepository: jobRepository,
          navKey: navKey,
        );
  }

  /// Resets instance to default.
  static void reset() {
    instance.dispose();
    instance = NotificationService._();
  }
}
