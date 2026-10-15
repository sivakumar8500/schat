import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'injection.config.dart';
import 'package:schat/utils/theme_controller.dart';

import 'package:schat/core/security/recording_permission_service.dart';

final getIt = GetIt.instance;
// ... (rest of imports)

@InjectableInit(
  initializerName: 'init', 
  preferRelativeImports: true, 
  asExtension: true, 
)
Future<void> configureDependencies() async {
  getIt.registerSingleton<ThemeController>(ThemeController()..loadTheme());
  await getIt.init();
  if (!getIt.isRegistered<RecordingPermissionService>()) {
    getIt.registerLazySingleton<RecordingPermissionService>(() => RecordingPermissionService());
  }
}

