import 'package:flutter_test/flutter_test.dart';
import 'package:schat/core/security/screen_protection_service.dart';
import 'package:schat/injection.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    if (!getIt.isRegistered<ScreenProtectionService>()) {
      getIt.registerLazySingleton<ScreenProtectionService>(() => ScreenProtectionService());
    }
  });

  group('ScreenProtectionService Tests', () {
    test('Service can be resolved from getIt', () {
      final service = getIt<ScreenProtectionService>();
      expect(service, isNotNull);
    });

    test('Streams are initialized correctly', () {
      final service = getIt<ScreenProtectionService>();
      expect(service.onScreenshot, isNotNull);
      expect(service.onScreenRecord, isNotNull);
    });
  });
}
