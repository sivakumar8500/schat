import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:schat/features/chat_screen/chat_screen.dart';
import 'package:schat/features/chat_screen/src/domain/models/message_model.dart';
import 'package:schat/features/chat_screen/src/domain/repositories/chat_repository.dart';
import 'package:schat/features/chat_socket_screen/src/domain/chat_socket_repository.dart';
import 'package:schat/features/chat_socket_screen/src/presentation/bloc/chat_socket_bloc.dart';
import 'package:schat/features/chat_socket_screen/src/domain/usecases/connect_socket_usecase.dart';
import 'package:schat/injection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MockChatRepository extends Mock implements ChatRepository {}
class MockChatSocketRepository extends Mock implements ChatSocketRepository {}
class MockConnectSocketUseCase extends Mock implements ConnectSocketUseCase {}
class MockChatSocketBloc extends Mock implements ChatSocketBloc {}

void main() {
  setUpAll(() {
    registerFallbackValue(const MessageModel(
      id: '',
      conversationId: '',
      senderId: '',
      content: '',
      isDeleted: false,
      createdAt: '',
      updatedAt: '',
    ));
  });

  late MockChatRepository mockChatRepository;
  late MockChatSocketRepository mockChatSocketRepository;
  late MockConnectSocketUseCase mockConnectSocketUseCase;

  setUp(() async {
    await getIt.reset();
    mockChatRepository = MockChatRepository();
    mockChatSocketRepository = MockChatSocketRepository();
    mockConnectSocketUseCase = MockConnectSocketUseCase();
    
    getIt.registerSingleton<ChatRepository>(mockChatRepository);
    getIt.registerSingleton<ChatSocketRepository>(mockChatSocketRepository);
    getIt.registerFactory<ChatSocketBloc>(() => ChatSocketBloc(mockConnectSocketUseCase, mockChatSocketRepository));

    when(() => mockChatSocketRepository.onMessage).thenAnswer((_) => const Stream.empty());
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: BlocProvider<ChatSocketBloc>(
        create: (context) => getIt<ChatSocketBloc>(),
        child: const ChatPage(
          conversationId: 'conv_1',
          contactName: 'Alice',
          contactColor: Colors.blue,
          isOnline: true,
          recipientId: 'user_1',
        ),
      ),
    );
  }

  testWidgets('ChatPage shows messages', (WidgetTester tester) async {
    when(() => mockChatRepository.getMessages(any())).thenAnswer(
      (_) async => [
        const MessageModel(
          id: '1',
          conversationId: 'conv_1',
          senderId: 'other',
          content: 'Hello',
          isDeleted: false,
          createdAt: '2026-06-14T10:00:00Z',
          updatedAt: '2026-06-14T10:00:00Z',
        ),
      ],
    );

    await tester.pumpWidget(createWidgetUnderTest());
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('Hello'), findsOneWidget);
    expect(find.text('Alice'), findsWidgets);
  });
}
