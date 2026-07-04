import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:schat/core/storage/storage_service.dart';
import 'package:schat/features/chat_screen/chat_screen.dart';
import 'package:schat/features/chat_screen/src/presentation/bloc/chat_bloc.dart';
import 'package:schat/features/chat_screen/src/presentation/bloc/chat_event.dart';
import 'package:schat/features/chat_screen/src/domain/models/message_model.dart';
import 'package:schat/features/chat_screen/src/presentation/widgets/message_bubble.dart';
import 'package:schat/features/chat_screen/src/domain/repositories/chat_repository.dart';
import 'package:schat/features/chat_socket_screen/src/domain/chat_socket_repository.dart';
import 'package:schat/features/chat_socket_screen/src/presentation/bloc/chat_socket_bloc.dart';
import 'package:schat/features/chat_socket_screen/src/domain/usecases/connect_socket_usecase.dart';
import 'package:schat/injection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schat/utils/common_icons.dart';
import 'package:flutter/services.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:schat/features/call_screen/src/presentation/bloc/call_webrtc_bloc.dart';
import 'package:schat/features/call_screen/src/presentation/bloc/call_webrtc_event.dart';
import 'package:schat/features/call_screen/src/presentation/bloc/call_webrtc_state.dart';

class MockChatRepository extends Mock implements ChatRepository {}
class MockChatSocketRepository extends Mock implements ChatSocketRepository {}
class MockConnectSocketUseCase extends Mock implements ConnectSocketUseCase {}
class MockChatSocketBloc extends Mock implements ChatSocketBloc {}
class MockStorageService extends Mock implements StorageService {}
class MockCallWebRtcBloc extends MockBloc<CallWebRtcEvent, CallWebRtcState> implements CallWebRtcBloc {}

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
  late MockCallWebRtcBloc mockCallWebRtcBloc;
  late Directory tempDir;

  setUp(() async {
    await getIt.reset();
    mockChatRepository = MockChatRepository();
    mockChatSocketRepository = MockChatSocketRepository();
    mockConnectSocketUseCase = MockConnectSocketUseCase();
    mockStorageService = MockStorageService();
    mockCallWebRtcBloc = MockCallWebRtcBloc();
    
    getIt.registerSingleton<ChatRepository>(mockChatRepository);
    getIt.registerSingleton<ChatSocketRepository>(mockChatSocketRepository);
    getIt.registerSingleton<StorageService>(mockStorageService);
    getIt.registerSingleton<CallWebRtcBloc>(mockCallWebRtcBloc);
    getIt.registerFactory<ChatSocketBloc>(() => ChatSocketBloc(mockConnectSocketUseCase, mockChatSocketRepository));

    when(() => mockChatSocketRepository.onMessage).thenAnswer((_) => const Stream.empty());
    when(() => mockChatSocketRepository.sendReadReceipt(any(), any())).thenAnswer((_) {});
    when(() => mockStorageService.getUserId()).thenReturn('my_id');
    when(() => mockCallWebRtcBloc.state).thenReturn(const CallIdle());
    when(() => mockCallWebRtcBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockChatRepository.getPinnedMessages(any())).thenAnswer((_) async => []);

    // Setup mock method channels to avoid MissingPluginException
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('com.llfbandit.record/messages'),
      (message) async => null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (message) async => null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      (message) async => null,
    );

    messenger.allMessagesHandler = (String channel, Future<ByteData?>? Function(ByteData?)? handler, ByteData? message) async {
      if (channel.startsWith('xyz.luan/audioplayers/events/') ||
          channel == 'xyz.luan/audioplayers.global/events') {
        return const StandardMethodCodec().encodeSuccessEnvelope(null);
      }
      return handler != null ? handler(message) : null;
    };

    // Initialize Hive to a temporary directory for test environment
    tempDir = await Directory.systemTemp.createTemp();
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.allMessagesHandler = null;
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
    when(() => mockChatRepository.getMessages(any(), limit: any(named: 'limit'), skip: any(named: 'skip'))).thenAnswer(
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
    when(() => mockChatRepository.getMessages(any(), limit: any(named: 'limit'), skip: any(named: 'skip'))).thenAnswer(
      (_) async => [],
    );

    await tester.runAsync(() async {
      await tester.pumpWidget(createWidgetUnderTest());
      await Future.delayed(const Duration(milliseconds: 500));
      await tester.pump();
    });

    // Grid should not be visible initially
    expect(find.text('Documents'), findsNothing);
    expect(find.text('Video'), findsNothing);
    expect(find.text('Gallery'), findsNothing);

    // Click the + button
    final plusButton = find.byIcon(CommonIcons.attach);
    expect(plusButton, findsOneWidget);
    await tester.tap(plusButton);
    await tester.pump();

    // Now the grid and items should be visible
    expect(find.text('Documents'), findsOneWidget);
    expect(find.text('Video'), findsOneWidget);
    expect(find.text('Gallery'), findsOneWidget);
    expect(find.text('Audio'), findsOneWidget);
    expect(find.text('Location'), findsOneWidget);
    expect(find.text('Contact'), findsOneWidget);

    // Click the close button (the + button toggled to close)
    final closeButton = find.byIcon(CommonIcons.close);
    expect(closeButton, findsOneWidget);
    await tester.tap(closeButton);
    await tester.pump();

    // Now grid items should not be visible anymore
    expect(find.text('Documents'), findsNothing);
  });

  testWidgets('ChatPage renders receiver message bubble with correct permission controls', (WidgetTester tester) async {
    when(() => mockChatRepository.getMessages(any(), limit: any(named: 'limit'), skip: any(named: 'skip'))).thenAnswer(
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
    expect(find.byIcon(CommonIcons.visibility), findsNWidgets(2));
    expect(find.byIcon(CommonIcons.download), findsOneWidget); // Only 1 (from msg_allow_all)
    expect(find.byIcon(CommonIcons.share), findsOneWidget); // Only 1 (from msg_allow_all)
  });

  testWidgets('ChatPage renders rich reply preview with file name when replying to file message', (WidgetTester tester) async {
    when(() => mockChatRepository.getMessages(any(), limit: any(named: 'limit'), skip: any(named: 'skip'))).thenAnswer(
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
    when(() => mockChatRepository.getMessages(any(), limit: any(named: 'limit'), skip: any(named: 'skip'))).thenAnswer(
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
    when(() => mockChatRepository.getMessages(any(), limit: any(named: 'limit'), skip: any(named: 'skip'))).thenAnswer(
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
    when(() => mockChatRepository.getMessages(any(), limit: any(named: 'limit'), skip: any(named: 'skip'))).thenAnswer(
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
    expect(find.byIcon(CommonIcons.errorOutline), findsOneWidget);
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

  testWidgets('ChatPage loads more messages when LoadMoreMessagesEvent is added', (WidgetTester tester) async {
    when(() => mockChatRepository.getMessages(
          any(),
          limit: any(named: 'limit'),
          skip: any(named: 'skip'),
        )).thenAnswer((invocation) async {
      final skip = invocation.namedArguments[#skip] as int?;
      if (skip == 0 || skip == null) {
        return List.generate(50, (index) => MessageModel(
          id: '${index + 2}',
          conversationId: 'conv_1',
          senderId: 'other',
          content: 'Message ${index + 2}',
          isDeleted: false,
          createdAt: '2026-06-14T10:02:00Z',
          updatedAt: '2026-06-14T10:02:00Z',
        ));
      } else {
        return [
          const MessageModel(
            id: '1',
            conversationId: 'conv_1',
            senderId: 'other',
            content: 'Message 1',
            isDeleted: false,
            createdAt: '2026-06-14T10:01:00Z',
            updatedAt: '2026-06-14T10:01:00Z',
          ),
        ];
      }
    });

    await tester.runAsync(() async {
      await tester.pumpWidget(createWidgetUnderTest());
      await Future.delayed(const Duration(milliseconds: 500));
      await tester.pump();
    });

    expect(find.text('Message 51'), findsOneWidget);
    expect(find.text('Message 1'), findsNothing);

    // Scroll to the top of the list to trigger lazy loading
    final ListView listView = tester.widget(find.byType(ListView));
    listView.controller!.jumpTo(listView.controller!.position.maxScrollExtent);
    await tester.pump();

    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 500));
      await tester.pump();
    });

    expect(find.text('Message 1'), findsOneWidget);
  });
}
