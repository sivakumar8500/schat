import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:schat/core/network/api_result.dart';
import 'package:schat/core/storage/storage_service.dart';
import 'package:schat/features/chat_screen/src/domain/models/message_model.dart';
import 'package:schat/features/chat_screen/src/domain/repositories/chat_repository.dart';
import 'package:schat/features/chat_screen/src/presentation/bloc/chat_bloc.dart';
import 'package:schat/features/chat_screen/src/presentation/bloc/chat_event.dart';
import 'package:schat/features/chat_screen/src/presentation/bloc/chat_state.dart';
import 'package:schat/features/chat_socket_screen/src/domain/chat_socket_repository.dart';
import 'package:schat/features/dashboard_screen/src/domain/repositories/contacts_repository.dart';
import 'package:schat/features/profile_screen/src/domain/models/user_model.dart';
import 'package:schat/features/profile_screen/src/domain/repositories/profile_repository.dart';
import 'package:schat/injection.dart';

class MockChatRepository extends Mock implements ChatRepository {}
class MockChatSocketRepository extends Mock implements ChatSocketRepository {}
class MockStorageService extends Mock implements StorageService {}
class MockProfileRepository extends Mock implements ProfileRepository {}
class MockContactsRepository extends Mock implements ContactsRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockChatRepository mockChatRepository;
  late MockChatSocketRepository mockChatSocketRepository;
  late MockStorageService mockStorageService;
  late MockProfileRepository mockProfileRepository;
  late MockContactsRepository mockContactsRepository;
  late StreamController<Map<String, dynamic>> socketStreamController;
  late Directory tempDir;

  setUpAll(() async {
    registerFallbackValue(const MessageModel(
      id: '',
      conversationId: '',
      senderId: '',
      content: '',
      isDeleted: false,
      createdAt: '',
      updatedAt: '',
    ));
    tempDir = await Directory.systemTemp.createTemp('hive_test_dir_');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    try {
      await Hive.close();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  setUp(() async {
    await getIt.reset();
    mockChatRepository = MockChatRepository();
    mockChatSocketRepository = MockChatSocketRepository();
    mockStorageService = MockStorageService();
    mockProfileRepository = MockProfileRepository();
    mockContactsRepository = MockContactsRepository();
    socketStreamController = StreamController<Map<String, dynamic>>.broadcast();

    getIt.registerSingleton<ChatRepository>(mockChatRepository);
    getIt.registerSingleton<ChatSocketRepository>(mockChatSocketRepository);
    getIt.registerSingleton<StorageService>(mockStorageService);
    getIt.registerSingleton<ProfileRepository>(mockProfileRepository);
    getIt.registerSingleton<ContactsRepository>(mockContactsRepository);

    when(() => mockChatSocketRepository.onMessage).thenAnswer((_) => socketStreamController.stream);
    when(() => mockChatSocketRepository.sendReadReceipt(any(), any())).thenAnswer((_) {});
    when(() => mockStorageService.getUserId()).thenReturn('user_me');
    when(() => mockStorageService.isChatLocked(any())).thenReturn(false);
    when(() => mockStorageService.getReadReceiptsEnabled()).thenReturn(true);
    when(() => mockChatRepository.getPinnedMessages(any())).thenAnswer((_) async => []);
    when(() => mockChatRepository.getLockedChats()).thenAnswer((_) async => []);
    when(() => mockChatRepository.getActiveScreenPermissions(any())).thenAnswer((_) async => []);
    when(() => mockChatRepository.getPendingScreenPermissions()).thenAnswer((_) async => []);
    when(() => mockContactsRepository.fetchSyncedContacts()).thenAnswer((_) async => ApiResult.success([]));
    when(() => mockProfileRepository.getUserById(any())).thenAnswer(
      (_) async => ApiResult.success(const UserModel(id: 'user_other', username: 'Bob', isOnline: true)),
    );

    final Map<String, Map<String, bool>> inMemoryPerms = {};
    when(() => mockStorageService.saveSenderMediaPermissions(
      any(),
      allowView: any(named: 'allowView'),
      allowDownload: any(named: 'allowDownload'),
      allowShare: any(named: 'allowShare'),
    )).thenAnswer((invocation) async {
      final key = invocation.positionalArguments[0] as String;
      final allowView = invocation.namedArguments[#allowView] as bool;
      final allowDownload = invocation.namedArguments[#allowDownload] as bool;
      final allowShare = invocation.namedArguments[#allowShare] as bool;
      final val = {'allowView': allowView, 'allowDownload': allowDownload, 'allowShare': allowShare};
      inMemoryPerms[key] = val;
      final fileName = key.split('?').first.split('/').last.trim();
      if (fileName.isNotEmpty) inMemoryPerms[fileName] = val;
    });

    when(() => mockStorageService.getSenderMediaPermissions(any()))
        .thenAnswer((invocation) {
      final key = invocation.positionalArguments[0] as String;
      if (inMemoryPerms.containsKey(key)) return inMemoryPerms[key];
      final fileName = key.split('?').first.split('/').last.trim();
      return inMemoryPerms[fileName];
    });

    // Clear hive boxes between tests
    if (Hive.isBoxOpen('cached_messages')) {
      await Hive.box('cached_messages').clear();
    }
  });

  tearDown(() async {
    await socketStreamController.close();
  });

  test('sending View-only media preserves allowView=true, allowDownload=false, allowShare=false after server echo', () async {
    when(() => mockChatRepository.getMessages(any(), limit: any(named: 'limit'), skip: any(named: 'skip')))
        .thenAnswer((_) async => []);

    final bloc = ChatBloc(
      chatRepository: mockChatRepository,
      socketRepository: mockChatSocketRepository,
      storageService: mockStorageService,
    );

    // Initial load
    bloc.add(const LoadMessagesEvent(conversationId: 'conv_1'));
    await bloc.stream.firstWhere((s) => s is ChatLoaded);

    // 1. User sends media with View-only (allowShare=false, allowDownload=false, allowView=true)
    const tempId = 'temp_12345';
    bloc.add(const SendMessageEvent(
      conversationId: 'conv_1',
      text: 'My Photo',
      type: 'image',
      attachmentPath: '/local/path/image.jpg',
      attachmentName: 'image.jpg',
      allowView: true,
      allowDownload: false,
      allowShare: false,
      messageId: tempId,
    ));

    await Future.delayed(const Duration(milliseconds: 50));
    var state = bloc.state as ChatLoaded;
    expect(state.messages.length, 1);
    expect(state.messages.first.allowView, true);
    expect(state.messages.first.allowDownload, false);
    expect(state.messages.first.allowShare, false);

    // 2. Server echoes back confirmed message
    // Even if server payload had allowDownload=true, allowShare=true (e.g. from backend owner root perms),
    // the frontend ChatBloc preserves the sender's configured permissions.
    final confirmedMsgData = {
      'id': 'msg_real_999',
      'conversationId': 'conv_1',
      'senderId': 'user_me',
      'content': {'text': 'My Photo', 'fileKey': 'https://s3.example.com/image.jpg'},
      'type': 'image',
      'userView': 'send',
      'attachmentName': 'image.jpg',
      'security': {
        'allowView': true,
        'allowDownload': true, // Server glitch/owner root perms
        'allowShare': true,
      },
      'isDeleted': false,
      'createdAt': '2026-10-16T12:00:00Z',
      'updatedAt': '2026-10-16T12:00:00Z',
    };

    bloc.add(ReceiveMessageEvent(messageData: confirmedMsgData));
    await Future.delayed(const Duration(milliseconds: 50));

    state = bloc.state as ChatLoaded;
    expect(state.messages.length, 1);
    final finalMsg = state.messages.first;
    expect(finalMsg.id, 'msg_real_999');
    expect(finalMsg.allowView, true, reason: 'allowView must be true');
    expect(finalMsg.allowDownload, false, reason: 'allowDownload must stay false');
    expect(finalMsg.allowShare, false, reason: 'allowShare must stay false');

    await bloc.close();
  });

  test('re-opening chat / fetching messages preserves View-only controls', () async {
    const existingMsg = MessageModel(
      id: 'msg_real_999',
      conversationId: 'conv_1',
      senderId: 'user_me',
      content: 'My Photo',
      mediaUrl: 'https://s3.example.com/image.jpg',
      mediaType: 'image',
      attachmentName: 'image.jpg',
      allowView: true,
      allowDownload: false,
      allowShare: false,
      isDeleted: false,
      createdAt: '2026-10-16T12:00:00Z',
      updatedAt: '2026-10-16T12:00:00Z',
    );

    // Cache the message in Hive 'cached_messages' box (same as used by ChatBloc._saveToCache)
    final box = await Hive.openBox('cached_messages');
    await box.put('conv_1', [existingMsg.toJson()]);

    // Simulate API returning the message with owner root perms (allowDownload=true, allowShare=true)
    when(() => mockChatRepository.getMessages('conv_1', limit: any(named: 'limit'), skip: any(named: 'skip')))
        .thenAnswer((_) async => [
          existingMsg.copyWith(
            allowDownload: true, // Remote server glitch / owner access
            allowShare: true,
          ),
        ]);

    final bloc = ChatBloc(
      chatRepository: mockChatRepository,
      socketRepository: mockChatSocketRepository,
      storageService: mockStorageService,
    );

    bloc.add(const LoadMessagesEvent(conversationId: 'conv_1'));
    // Wait for the background API fetch to complete
    await bloc.stream.firstWhere((s) => s is ChatLoaded && s.messages.isNotEmpty);
    await Future.delayed(const Duration(milliseconds: 100));

    final state = bloc.state as ChatLoaded;
    expect(state.messages.length, 1);
    final msg = state.messages.first;
    expect(msg.allowView, true);
    expect(msg.allowDownload, false, reason: 'allowDownload must not auto-enable on reopen');
    expect(msg.allowShare, false, reason: 'allowShare must not auto-enable on reopen');

    await bloc.close();
  });
}
