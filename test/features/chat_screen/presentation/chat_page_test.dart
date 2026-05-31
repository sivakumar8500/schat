import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:schat/features/chat_screen/chat_screen.dart';
import 'package:schat/features/chat_screen/src/domain/models/message_model.dart';
import 'package:schat/features/chat_screen/src/domain/repositories/chat_repository.dart';
import 'package:schat/injection.dart';

class MockChatRepository extends Mock implements ChatRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(const MessageModel(id: '', text: '', time: '', isMe: true));
  });

  late MockChatRepository mockChatRepository;

  setUp(() async {
    await getIt.reset();
    mockChatRepository = MockChatRepository();
    getIt.registerSingleton<ChatRepository>(mockChatRepository);
  });

  Widget createWidgetUnderTest() {
    return const MaterialApp(
      home: ChatPage(
        contactName: 'Alice',
        contactColor: Colors.blue,
        isOnline: true,
      ),
    );
  }

  testWidgets('ChatPage shows messages', (WidgetTester tester) async {
    when(() => mockChatRepository.getMessages(any())).thenAnswer(
      (_) async => [
        const MessageModel(id: '1', text: 'Hello', time: '10:00 AM', isMe: false),
      ],
    );

    await tester.pumpWidget(createWidgetUnderTest());
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('Hello'), findsOneWidget);
    expect(find.text('Alice'), findsWidgets);
  });

  testWidgets('ChatPage sends message', (WidgetTester tester) async {
    when(() => mockChatRepository.getMessages(any())).thenAnswer((_) async => []);
    when(() => mockChatRepository.sendMessage(any())).thenAnswer((_) async => true);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'My new message');
    await tester.pump();
    
    // Tap send icon
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();

    verify(() => mockChatRepository.sendMessage(any())).called(1);
    expect(find.text('My new message'), findsOneWidget);
  });
}
