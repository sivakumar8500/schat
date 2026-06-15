import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schat/features/splash_screen/splash_screen.dart';
import 'package:schat/utils/theme_controller.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:schat/common/widgets/internet_connection_popup_widget.dart';
import 'package:schat/features/connectivity/src/presentation/bloc/connectivity_bloc.dart';
import 'package:schat/features/connectivity/src/presentation/bloc/connectivity_event.dart';
import 'package:schat/features/chat_socket_screen/src/presentation/bloc/chat_socket_bloc.dart';
import 'package:schat/features/chat_socket_screen/src/presentation/bloc/chat_socket_event.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'injection.dart';

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Initialize Hive
    await Hive.initFlutter();
    
    configureDependencies();
    
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        await ScreenProtector.preventScreenshotOn();
      } catch (e) {
        debugPrint('ScreenProtector error: $e');
      }
    }
    
    runApp(const MyApp());
  } catch (e, stackTrace) {
    debugPrint('Initialization error: $e');
    debugPrint('Stack trace: $stackTrace');
    // Still try to run the app or show a crash screen
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('App initialization failed: $e'),
        ),
      ),
    ));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: getIt<ThemeController>(),
      builder: (context, _) {
        return MultiBlocProvider(
          providers: [
            BlocProvider<ConnectivityBloc>(
              create: (context) => getIt<ConnectivityBloc>()..add(ConnectivityStarted()),
            ),
            BlocProvider<ChatSocketBloc>(
              create: (context) => getIt<ChatSocketBloc>()..add(const ConnectSocket()),
            ),
          ],
          child: MaterialApp(
            title: 'sChat',
            themeMode: getIt<ThemeController>().themeMode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: context.colors.primary,
              brightness: Brightness.light,
              surface: context.colors.scaffoldBackground,
            ),
            scaffoldBackgroundColor: context.colors.scaffoldBackground,
            useMaterial3: true,
            fontFamily: GoogleFonts.poppins().fontFamily,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: context.colors.primary,
              brightness: Brightness.dark,
              surface: context.colors.scaffoldBackground,
            ),
            scaffoldBackgroundColor: context.colors.scaffoldBackground,
            useMaterial3: true,
            fontFamily: GoogleFonts.poppins().fontFamily,
          ),
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(getIt<ThemeController>().textScaleFactor),
              ),
              child: Stack(
                children: [
                  child!,
                  const InternetConnectionPopup(),
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
