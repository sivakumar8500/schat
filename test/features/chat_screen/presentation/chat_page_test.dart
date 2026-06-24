import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:schat/core/storage/storage_service.dart';
import 'package:schat/features/chat_screen/chat_screen.dart';
import 'package:schat/features/chat_screen/src/domain/models/message_model.dart';
import 'package:schat/features/chat_screen/src/presentation/widgets/message_bubble.dart';
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
class MockStorageService extends Mock implements StorageService {}

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
  late MockStorageService mockStorageService;
  late Directory tempDir;

  setUp(() async {
    await getIt.reset();
    mockChatRepository = MockChatRepository();
    mockChatSocketRepository = MockChatSocketRepository();
    mockConnectSocketUseCase = MockConnectSocketUseCase();
    mockStorageService = MockStorageService();
    
    getIt.registerSingleton<ChatRepository>(mockChatRepository);
    getIt.registerSingleton<ChatSocketRepository>(mockChatSocketRepository);
    getIt.registerSingleton<StorageService>(mockStorageService);
    getIt.registerFactory<ChatSocketBloc>(() => ChatSocketBloc(mockConnectSocketUseCase, mockChatSocketRepository));

    when(() => mockChatSocketRepository.onMessage).thenAnswer((_) => const Stream.empty());
    when(() => mockChatSocketRepository.sendReadReceipt(any(), any())).thenAnswer((_) {});
    when(() => mockStorageService.getUserId()).thenReturn('my_id');

    // Initialize Hive to a temporary directory for test environment
    tempDir = await Directory.systemTemp.createTemp();
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
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

    await tester.runAsync(() async {
      await tester.pumpWidget(createWidgetUnderTest());
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for Hive disk I/O and async repository call to complete
      await Future.delayed(const Duration(milliseconds: 500));
      await tester.pump();
    });

    expect(find.text('Hello'), findsOneWidget);
    expect(find.text('Alice'), findsWidgets);
  });

  testWidgets('ChatPage toggles media attachment grid when clicking + button', (WidgetTester tester) async {
    when(() => mockChatRepository.getMessages(any())).thenAnswer(
      (_) async => [],
    );

    await tester.runAsync(() async {
      await tester.pumpWidget(createWidgetUnderTest());
      await Future.delayed(const Duration(milliseconds: 500));
      await tester.pump();
    });

    // Grid should not be visible initially
    expect(find.text('Document'), findsNothing);
    expect(find.text('Camera'), findsNothing);
    expect(find.text('Gallery'), findsNothing);

    // Click the + button
    final plusButton = find.byIcon(Icons.add_rounded);
    expect(plusButton, findsOneWidget);
    await tester.tap(plusButton);
    await tester.pump();

    // Now the grid and items should be visible
    expect(find.text('Document'), findsOneWidget);
    expect(find.text('Camera'), findsOneWidget);
    expect(find.text('Gallery'), findsOneWidget);
    expect(find.text('Audio'), findsOneWidget);
    expect(find.text('Location'), findsOneWidget);
    expect(find.text('Contact'), findsOneWidget);

    // Click the close button (the + button toggled to close)
    final closeButton = find.byIcon(Icons.close);
    expect(closeButton, findsOneWidget);
    await tester.tap(closeButton);
    await tester.pump();

    // Now grid items should not be visible anymore
    expect(find.text('Document'), findsNothing);
  });

  testWidgets('ChatPage renders receiver message bubble with correct permission controls', (WidgetTester tester) async {
    when(() => mockChatRepository.getMessages(any())).thenAnswer(
      (_) async => [
        const MessageModel(
          id: 'msg_allow_all',
          conversationId: 'conv_1',
          senderId: 'other',
          content: 'File name',
          mediaUrl: 'some_file_url.pdf',
          mediaType: 'file',
          isDeleted: false,
          createdAt: '2026-06-14T10:00:00Z',
          updatedAt: '2026-06-14T10:00:00Z',
          allowView: true,
          allowDownload: true,
          allowShare: true,
        ),
        const MessageModel(
          id: 'msg_locked_all',
          conversationId: 'conv_1',
          senderId: 'other',
          content: 'Secret file',
          mediaUrl: 'secret.pdf',
          mediaType: 'file',
          isDeleted: false,
          createdAt: '2026-06-14T10:01:00Z',
          updatedAt: '2026-06-14T10:01:00Z',
          allowView: true,
          allowDownload: false,
          allowShare: false,
        ),
      ],
    );

    await tester.runAsync(() async {
      await tester.pumpWidget(createWidgetUnderTest());
      await Future.delayed(const Duration(milliseconds: 500));
      await tester.pump();
    });

    // Check message action counts
    expect(find.byIcon(Icons.visibility), findsNWidgets(2));
    expect(find.byIcon(Icons.download), findsOneWidget); // Only 1 (from msg_allow_all)
    expect(find.byIcon(Icons.share), findsOneWidget); // Only 1 (from msg_allow_all)
  });

  testWidgets('ChatPage renders rich reply preview with file name when replying to file message', (WidgetTester tester) async {
    when(() => mockChatRepository.getMessages(any())).thenAnswer(
      (_) async => [
        const MessageModel(
          id: 'parent_file_msg',
          conversationId: 'conv_1',
          senderId: 'other',
          content: '',
          mediaUrl: 'some_doc.pdf',
          mediaType: 'file',
          attachmentName: 'Invoice_Details.pdf',
          isDeleted: false,
          createdAt: '2026-06-14T10:00:00Z',
          updatedAt: '2026-06-14T10:00:00Z',
        ),
      ],
    );

    await tester.runAsync(() async {
      await tester.pumpWidget(createWidgetUnderTest());
      await Future.delayed(const Duration(milliseconds: 500));
      await tester.pump();
    });

    // Verify parent file message is displayed
    expect(find.text('Invoice_Details.pdf'), findsOneWidget);

    // Long press the parent message to open the menu and select "Reply"
    final parentMessageBubble = find.text('Invoice_Details.pdf');
    await tester.longPress(parentMessageBubble);
    await tester.pumpAndSettle();

    // Tap "Reply" menu item
    final replyItem = find.text('Reply');
    expect(replyItem, findsOneWidget);
    await tester.tap(replyItem);
    await tester.pumpAndSettle();

    // Now the reply preview should be visible above input field showing the file name
    expect(find.text('Replying to Message'), findsOneWidget);
    expect(find.text('Invoice_Details.pdf'), findsNWidgets(2)); // One in chat history, one in reply preview
  });

  testWidgets('ChatPage filters out deleted messages from the chat list', (WidgetTester tester) async {
    when(() => mockChatRepository.getMessages(any())).thenAnswer(
      (_) async => [
        const MessageModel(
          id: 'deleted_msg_1',
          conversationId: 'conv_1',
          senderId: 'other',
          content: 'This message was deleted',
          isDeleted: true,
          createdAt: '2026-06-14T10:00:00Z',
          updatedAt: '2026-06-14T10:00:00Z',
        ),
        const MessageModel(
          id: 'visible_msg_2',
          conversationId: 'conv_1',
          senderId: 'other',
          content: 'Hello World',
          isDeleted: false,
          createdAt: '2026-06-14T10:05:00Z',
          updatedAt: '2026-06-14T10:05:00Z',
        ),
      ],
    );

    await tester.runAsync(() async {
      await tester.pumpWidget(createWidgetUnderTest());
      await Future.delayed(const Duration(milliseconds: 500));
      await tester.pump();
    });

    // Verify visible message is displayed
    expect(find.text('Hello World'), findsOneWidget);
    // Verify deleted message is not displayed
    expect(find.text('This message was deleted'), findsNothing);
  });

  testWidgets('ChatPage renders link messages with clickable blue styling', (WidgetTester tester) async {
    when(() => mockChatRepository.getMessages(any())).thenAnswer(
      (_) async => [
        const MessageModel(
          id: 'link_msg',
          conversationId: 'conv_1',
          senderId: 'other',
          content: 'Check this out: www.google.com and have fun',
          isDeleted: false,
          createdAt: '2026-06-14T10:00:00Z',
          updatedAt: '2026-06-14T10:00:00Z',
        ),
      ],
    );

    await tester.runAsync(() async {
      await tester.pumpWidget(createWidgetUnderTest());
      await Future.delayed(const Duration(milliseconds: 500));
      await tester.pump();
    });

    // Check that the message containing the URL is rendered using RichText with correct URL TextSpan
    final bubbleFinder = find.byType(MessageBubble);
    expect(bubbleFinder, findsOneWidget);
    
    final richTextFinder = find.descendant(
      of: bubbleFinder,
      matching: find.byType(RichText),
    );
    final richTexts = tester.widgetList<RichText>(richTextFinder);
    
    bool foundLink = false;
    for (final richText in richTexts) {
      final textSpan = richText.text;
      if (textSpan is TextSpan) {
        final hasLink = textSpan.children?.any((span) {
          return span is TextSpan && span.text == 'www.google.com';
        }) ?? false;
        if (hasLink) {
          foundLink = true;
          break;
        }
      }
    }
    
    expect(foundLink, isTrue);
  });

  testWidgets('ChatPage renders Resend button when isFailed is true', (WidgetTester tester) async {
    when(() => mockChatRepository.getMessages(any())).thenAnswer(
      (_) async => [
        const MessageModel(
          id: 'failed_msg',
          conversationId: 'conv_1',
          senderId: 'my_id',
          content: 'Failed message content',
          isDeleted: false,
          createdAt: '2026-06-14T10:00:00Z',
          updatedAt: '2026-06-14T10:00:00Z',
          isFailed: true,
        ),
      ],
    );

    await tester.runAsync(() async {
      await tester.pumpWidget(createWidgetUnderTest());
      await Future.delayed(const Duration(milliseconds: 500));
      await tester.pump();
    });

    // Check that 'Resend' button is displayed
    expect(find.text('Resend'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });

  test('MessageModel.fromJson handles dynamic decodings of content map', () {
    final Map<dynamic, dynamic> contentMap = {
      'text': 'Dynamic map decoded content',
      'fileKey': 'some_key',
    };
    final Map<String, dynamic> rawJson = {
      'id': 'json_msg',
      'conversationId': 'conv_1',
      'senderId': 'other',
      'content': contentMap,
      'isDeleted': false,
      'createdAt': '2026-06-14T10:00:00Z',
      'updatedAt': '2026-06-14T10:00:00Z',
    };

    final message = MessageModel.fromJson(rawJson);
    expect(message.content, 'Dynamic map decoded content');
    expect(message.mediaUrl, 'some_key');
  });
}
