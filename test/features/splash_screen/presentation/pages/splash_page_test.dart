import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:schat/features/splash_screen/splash_screen.dart';
import 'package:schat/core/storage/storage_service.dart';
import 'package:schat/features/profile_screen/src/domain/repositories/profile_repository.dart';
import 'package:schat/injection.dart';
import 'package:schat/utils/theme_controller.dart';
import 'package:schat/utils/common_icons.dart';

class MockStorageService extends Mock implements StorageService {}
class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late MockStorageService mockStorage;
  late MockProfileRepository mockProfileRepo;

  setUp(() async {
    mockStorage = MockStorageService();
    mockProfileRepo = MockProfileRepository();
    await getIt.reset();
    getIt.registerSingleton<StorageService>(mockStorage);
    getIt.registerSingleton<ProfileRepository>(mockProfileRepo);
    getIt.registerSingleton<ThemeController>(ThemeController());
    
    SharedPreferences.setMockInitialValues({});
    
    when(() => mockStorage.hasToken()).thenAnswer((_) async => false);
  });

  Widget createWidgetUnderTest() {
    return const MaterialApp(
      home: SplashPage(),
    );
  }

  testWidgets('SplashPage renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    // Verify UI
    expect(find.text('Schat'), findsOneWidget);
    expect(find.byIcon(CommonIcons.chatBubble), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Let the timer finish
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });
}
