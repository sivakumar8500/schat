import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schat/features/splash_screen/splash_screen.dart';
import 'package:schat/utils/theme_controller.dart';
import 'package:schat/common/widgets/internet_connection_popup_widget.dart';
import 'package:schat/features/connectivity/src/presentation/bloc/connectivity_bloc.dart';
import 'package:schat/features/connectivity/src/presentation/bloc/connectivity_event.dart';
import 'package:schat/features/chat_socket_screen/src/presentation/bloc/chat_socket_bloc.dart';
import 'package:schat/features/call_screen/src/presentation/bloc/call_webrtc_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:schat/utils/common_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:schat/firebase_options.dart';
import 'package:schat/core/notifications/call_notification_service.dart';
import 'package:schat/core/security/screen_protection_service.dart';
import 'package:schat/features/call_screen/src/presentation/widgets/minimized_call_overlay.dart';
import 'package:schat/utils/common_notifications.dart';
import 'injection.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Register background message handler
    FirebaseMessaging.onBackgroundMessage(CallNotificationService.handleBackgroundMessage);

    // Initialize Hive
    await Hive.initFlutter();

    await configureDependencies();

    // Initialize CallNotificationService
    await getIt<CallNotificationService>().initialize();
    
    // Initialize ScreenProtectionService
    await getIt<ScreenProtectionService>().initialize();
    
    // Initialize CallWebRtcBloc to start listening for call events
    getIt<CallWebRtcBloc>();

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

class _MyAppState extends State<MyApp> {
  StreamSubscription? _screenshotSubscription;
  StreamSubscription? _recordSubscription;

  @override
  void initState() {
    super.initState();
    _setupSecurityListeners();
  }

  void _setupSecurityListeners() {
    // Security listeners disabled as requested
  }

  @override
  void dispose() {
    _screenshotSubscription?.cancel();
    _recordSubscription?.cancel();
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
            ),
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(
                    getIt<ThemeController>().textScaleFactor,
                  ),
                ),
                child: Stack(
                  children: [
                    child!,
                    const InternetConnectionPopup(),
                    const MinimizedCallOverlay(),
                  ],
                ),
              );
            },
            home: const SplashPage(),
          ),
        );
      },
    );
  }
}
