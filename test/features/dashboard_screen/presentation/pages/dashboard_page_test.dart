import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schat/features/dashboard_screen/dashboard_screen.dart';
import 'package:schat/injection.dart';
import 'package:schat/utils/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:schat/features/chat_screen/src/domain/repositories/chat_repository.dart';
import 'package:schat/features/status_screen/src/domain/repositories/status_repository.dart';
import 'package:mocktail/mocktail.dart';
class MockChatRepository extends Mock implements ChatRepository {}
class MockStatusRepository extends Mock implements StatusRepository {}

void main() {
  setUp(() async {
    await getIt.reset();
    getIt.registerSingleton<ThemeController>(ThemeController());
    getIt.registerSingleton<ChatRepository>(MockChatRepository());
    
    final statusRepo = MockStatusRepository();
    when(() => statusRepo.getRecentUpdates()).thenAnswer((_) async => []);
    when(() => statusRepo.getViewedUpdates()).thenAnswer((_) async => []);
    when(() => statusRepo.getMutedUpdates()).thenAnswer((_) async => []);
    getIt.registerSingleton<StatusRepository>(statusRepo);
    SharedPreferences.setMockInitialValues({});
  });

  Widget createWidgetUnderTest() {
    return const MaterialApp(
      home: DashboardPage(),
    );
  }

  testWidgets('DashboardPage renders Header and Chat List correctly', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    // Verify Header title
    expect(find.text('Messages'), findsOneWidget);
    // Verify custom Chat list renders
    expect(find.byType(ListView), findsOneWidget);

    // Verify dummy data renders in ListView
    expect(find.text('Alice Smith'), findsOneWidget);
    expect(find.text('Bob Johnson'), findsOneWidget);
    
    // Verify FAB exists
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byIcon(Icons.edit), findsOneWidget);
  });

  testWidgets('DashboardPage bottom navigation bar updates state', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    // Verify initial tab (Chats)
    final bottomNav = tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
    expect(bottomNav.currentIndex, 0);

    // Tap 'Status' tab by Icon since labels are hidden
    await tester.tap(find.byIcon(Icons.auto_awesome_mosaic_rounded));
    await tester.pumpAndSettle();

    // Verify index updated
    final updatedBottomNav = tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
    expect(updatedBottomNav.currentIndex, 1);
  });

  testWidgets('DashboardPage settings allow changing font size and persists it', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    // Tap Profile tab (Index 3, Icons.person_outline_rounded)
    await tester.tap(find.byIcon(Icons.person_outline_rounded));
    await tester.pumpAndSettle();

    // Verify we are on Profile tab (Edit Profile button exists)
    expect(find.text('Edit Profile'), findsOneWidget);

    // Verify Font Size setting label and Dropdown exist
    expect(find.text('Font Size'), findsOneWidget);
    expect(find.byType(DropdownButton<String>), findsOneWidget);

    // Change Dropdown value to Large
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();

    // Tap the 'Large' option in the dropdown popup list
    await tester.tap(find.text('Large').last);
    await tester.pumpAndSettle();

    // Verify ThemeController state updated
    expect(getIt<ThemeController>().fontSizeName, 'Large');
    expect(getIt<ThemeController>().textScaleFactor, 1.2);
  });
}
