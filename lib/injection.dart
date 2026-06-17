import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'injection.config.dart';
import 'package:schat/utils/theme_controller.dart';

final getIt = GetIt.instance;

@InjectableInit(
  initializerName: 'init', 
  preferRelativeImports: true, 
  asExtension: true, 
)
Future<void> configureDependencies() async {
  getIt.registerSingleton<ThemeController>(ThemeController()..loadTheme());
  await getIt.init();
}
