import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schat/features/status_screen/src/domain/repositories/status_repository.dart';
import 'package:schat/features/status_screen/src/domain/status_model.dart';
import 'package:schat/features/status_screen/src/presentation/status_page.dart';

import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

class MockStatusRepository extends Mock implements StatusRepository {}

void main() {
  late MockStatusRepository mockStatusRepository;

  setUp(() {
    mockStatusRepository = MockStatusRepository();
    if (GetIt.I.isRegistered<StatusRepository>()) {
      GetIt.I.unregister<StatusRepository>();
    }
    GetIt.I.registerSingleton<StatusRepository>(mockStatusRepository);
  });

  Widget createWidgetUnderTest() {
    return const MaterialApp(
      home: StatusPage(),
    );
  }

  testWidgets('StatusPage should render My Status correctly', (WidgetTester tester) async {
    when(() => mockStatusRepository.getRecentUpdates()).thenAnswer((_) async => []);
    when(() => mockStatusRepository.getViewedUpdates()).thenAnswer((_) async => []);
    when(() => mockStatusRepository.getMutedUpdates()).thenAnswer((_) async => []);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('My Status'), findsWidgets);
    expect(find.text('Add to my status'), findsOneWidget);
  });

  testWidgets('StatusPage should display recent updates when loaded', (WidgetTester tester) async {
    when(() => mockStatusRepository.getRecentUpdates()).thenAnswer(
      (_) async => [
        StatusContactModel(
          contactId: '1',
          name: 'Siva',
          profileColor: Colors.blue,
          statuses: [
            StatusItemModel(
              id: '1',
              timestamp: DateTime.now(),
              text: 'Hello',
            )
          ],
        )
      ],
    );
    when(() => mockStatusRepository.getViewedUpdates()).thenAnswer((_) async => []);
    when(() => mockStatusRepository.getMutedUpdates()).thenAnswer((_) async => []);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Recent Updates'), findsWidgets);
    expect(find.text('Siva'), findsOneWidget);
  });
}
