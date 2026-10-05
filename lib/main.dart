import 'dart:async';
import 'package:schat/utils/common_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schat/features/splash_screen/splash_screen.dart';
import 'package:schat/utils/theme_controller.dart';
import 'package:schat/common/widgets/internet_connection_popup_widget.dart';
import 'package:schat/features/connectivity/src/presentation/bloc/connectivity_bloc.dart';
import 'package:schat/features/connectivity/src/presentation/bloc/connectivity_event.dart';
import 'package:schat/features/chat_socket_screen/src/presentation/bloc/chat_socket_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:schat/utils/common_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:schat/firebase_options.dart';
import 'package:schat/core/notifications/call_notification_service.dart';
import 'package:schat/core/notifications/push_notification_service.dart';
import 'package:schat/core/notifications/in_app_notification_service.dart';
import 'package:schat/features/chat_socket_screen/src/domain/chat_socket_repository.dart';
import 'package:schat/features/call_screen/call_screen.dart';
import 'package:schat/features/call_screen/src/presentation/bloc/call_history_cubit.dart';
import 'package:schat/core/security/screen_protection_service.dart';
import 'package:schat/core/storage/storage_service.dart';
import 'package:schat/features/call_screen/src/presentation/widgets/minimized_call_overlay.dart';
import 'package:schat/features/call_screen/src/presentation/widgets/pip_call_view.dart';

import 'injection.dart';

import 'package:schat/features/dashboard_screen/src/presentation/bloc/chats_bloc.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/chats_event.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/contacts_bloc.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/contacts_event.dart';
import 'package:schat/core/services/share_receiver_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  CallNotificationService.printCallLog(
    stage: 'FCM TOP-LEVEL BACKGROUND HANDLER STARTED',
    payload: message.data,
    note: 'Message ID: ${message.messageId} | Has Notification Payload: ${message.notification != null}',
  );

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e, st) {
    CallNotificationService.printCallLog(
      stage: 'FIREBASE BACKGROUND INITIALIZATION EXCEPTION',
      exception: e,
      stackTrace: st,
    );
  }

  await CallNotificationService.handleBackgroundMessage(message);
}

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Register top-level background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Initialize Hive
    await Hive.initFlutter();
    try {
      await Hive.openBox('opened_view_once_messages');
    } catch (e) {
      debugPrint('Error opening opened_view_once_messages box: $e');
    }

    await configureDependencies();

    // Initialize CallNotificationService
    await getIt<CallNotificationService>().initialize();
    
    // Initialize CallWebRtcBloc to start listening for call events
    getIt<CallWebRtcBloc>();

    // Initialize InAppNotificationService
    getIt<InAppNotificationService>().initialize();

    // Initialize PushNotificationService
    await getIt<PushNotificationService>().initialize();
    await getIt<PushNotificationService>().registerToken();

    // Initialize ScreenProtectionService
    await getIt<ScreenProtectionService>().initialize();

    runApp(const MyApp());
  } catch (e, stackTrace) {
    debugPrint('Initialization error: $e');
    debugPrint('Stack trace: $stackTrace');
    // Still try to run the app or show a crash screen
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(child: Text('App initialization failed: $e')),
        ),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ShareReceiverService().init();
  }

  /// Reconnect the WebSocket when the app comes back to the foreground.
  /// This handles the case where the user accepts a call via the CallKit
  /// notification and the app resumes from a background/killed state.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      final repo = getIt<ChatSocketRepository>();
      repo.onAppResumed();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ShareReceiverService().dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: getIt<ThemeController>(),
      builder: (context, _) {
        return MultiBlocProvider(
          providers: [
            BlocProvider<ConnectivityBloc>(
              create: (context) =>
                  getIt<ConnectivityBloc>()..add(ConnectivityStarted()),
            ),
            BlocProvider<ChatSocketBloc>(
              create: (context) => getIt<ChatSocketBloc>(),
            ),
            BlocProvider<CallWebRtcBloc>(
              create: (context) => getIt<CallWebRtcBloc>(),
            ),
            BlocProvider.value(
              value: getIt<CallHistoryCubit>()..fetchCallHistory(),
            ),
            BlocProvider.value(
              value: getIt<ChatsBloc>()..add(const FetchChats()),
            ),
            BlocProvider.value(
              value: getIt<ContactsBloc>()..add(const LoadContacts()),
            ),
          ],
          child: MaterialApp(
            title: 'sChat',
            navigatorKey: navigatorKey,
            navigatorObservers: [routeObserver],
            themeMode: getIt<ThemeController>().themeMode,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: context.colors.primary,
                brightness: Brightness.light,
                surface: context.colors.scaffoldBackground,
              ),
              scaffoldBackgroundColor: context.colors.scaffoldBackground,
              useMaterial3: true,
              fontFamily: CommonFonts.primaryFont,
              inputDecorationTheme: InputDecorationTheme(
                hintStyle: TextStyle(
                  fontFamily: CommonFonts.primaryFont,
                  fontSize: 18,
                  color: context.colors.textHint,
                ),
                labelStyle: TextStyle(
                  fontFamily: CommonFonts.primaryFont,
                  fontSize: 18,
                  color: context.colors.textSecondary,
                ),
              ),
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: context.colors.primary,
                brightness: Brightness.dark,
                surface: context.colors.scaffoldBackground,
              ),
              scaffoldBackgroundColor: context.colors.scaffoldBackground,
              useMaterial3: true,
              fontFamily: CommonFonts.primaryFont,
              inputDecorationTheme: InputDecorationTheme(
                hintStyle: TextStyle(
                  fontFamily: CommonFonts.primaryFont,
                  fontSize: 18,
                  color: context.colors.textHint,
                ),
                labelStyle: TextStyle(
                  fontFamily: CommonFonts.primaryFont,
                  fontSize: 18,
                  color: context.colors.textSecondary,
                ),
              ),
            ),
            builder: (context, child) {
              return BlocBuilder<CallWebRtcBloc, CallWebRtcState>(
                builder: (context, callState) {
                  final isSystemPip = (callState is CallActive && callState.isSystemPip) ||
                      (callState is CallConnecting && callState.isSystemPip);

                  return MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      textScaler: TextScaler.linear(
                        getIt<ThemeController>().textScaleFactor,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Offstage(
                          offstage: isSystemPip,
                          child: child ?? const SizedBox.shrink(),
                        ),
                        if (isSystemPip)
                          Positioned.fill(
                            child: Material(
                              color: Colors.black,
                              child: PipCallView(state: callState),
                            ),
                          )
                        else ...[
                          const InternetConnectionPopup(),
                          const MinimizedCallOverlay(),
                          if (callState is CallRinging)
                            Positioned.fill(
                              child: IncomingCallDialog(
                                incomingEvent: callState.incomingEvent,
                                callerName: callState.callerName,
                                callerColor: Colors.blue,
                                isVideo: callState.isVideo,
                                conversationId: (callState.incomingEvent['conversation_id'] ?? callState.incomingEvent['conversationId'])?.toString() ?? '',
                                recipientId: callState.recipientId,
                                profilePictureUrl: callState.profilePictureUrl,
                              ),
                            ),
                          if (((callState is CallActive && !callState.isMinimized) ||
                                  (callState is CallConnecting && !callState.isMinimized)) &&
                              !CallWebRtcBloc.isCallScreenMounted)
                            Positioned.fill(
                              child: Material(
                                child: (callState is CallActive
                                        ? callState.isVideo
                                        : (callState as CallConnecting).isVideo)
                                    ? VideoCallPage(
                                        conversationId: callState is CallActive
                                            ? callState.conversationId
                                            : (callState as CallConnecting).conversationId,
                                        contactName: callState is CallActive
                                            ? callState.contactName
                                            : (callState as CallConnecting).contactName,
                                        contactColor: Colors.blue,
                                        recipientId: callState is CallActive
                                            ? callState.recipientId
                                            : (callState as CallConnecting).recipientId,
                                        isOutgoing: false,
                                        profilePictureUrl: callState is CallActive
                                            ? callState.profilePictureUrl
                                            : (callState as CallConnecting).profilePictureUrl,
                                        myProfilePictureUrl: getIt<StorageService>().getProfilePic(),
                                        isGroup: callState is CallActive
                                            ? callState.isGroup
                                            : (callState as CallConnecting).isGroup,
                                        groupName: callState is CallActive
                                            ? callState.groupName
                                            : (callState as CallConnecting).groupName,
                                        extraParticipants: callState is CallActive
                                            ? callState.extraParticipants
                                            : (callState as CallConnecting).extraParticipants,
                                      )
                                    : AudioCallPage(
                                        conversationId: callState is CallActive
                                            ? callState.conversationId
                                            : (callState as CallConnecting).conversationId,
                                        contactName: callState is CallActive
                                            ? callState.contactName
                                            : (callState as CallConnecting).contactName,
                                        contactColor: Colors.blue,
                                        recipientId: callState is CallActive
                                            ? callState.recipientId
                                            : (callState as CallConnecting).recipientId,
                                        isOutgoing: false,
                                        profilePictureUrl: callState is CallActive
                                            ? callState.profilePictureUrl
                                            : (callState as CallConnecting).profilePictureUrl,
                                        myProfilePictureUrl: getIt<StorageService>().getProfilePic(),
                                        isGroup: callState is CallActive
                                            ? callState.isGroup
                                            : (callState as CallConnecting).isGroup,
                                        groupName: callState is CallActive
                                            ? callState.groupName
                                            : (callState as CallConnecting).groupName,
                                        extraParticipants: callState is CallActive
                                            ? callState.extraParticipants
                                            : (callState as CallConnecting).extraParticipants,
                                      ),
                              ),
                            ),
                        ],
                      ],
                    ),
                  );
                },
              );
            },
            home: const SplashPage(),
          ),
        );
      },
    );
  }
}
