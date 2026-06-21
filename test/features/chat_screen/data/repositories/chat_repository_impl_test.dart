import 'dart:io';
import 'package:hive/hive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:schat/core/network/api_service.dart';
import 'package:schat/core/storage/storage_service.dart';
import 'package:schat/features/chat_screen/src/data/repositories/chat_repository_impl.dart';
import 'package:schat/features/chat_screen/src/domain/models/message_model.dart';
import 'package:schat/features/chat_screen/src/domain/models/chat_media_model.dart';
import 'package:schat/features/chat_screen/src/domain/repositories/chat_repository.dart';
import 'package:schat/features/chat_screen/src/presentation/bloc/chat_bloc.dart';
import 'package:schat/features/chat_screen/src/presentation/bloc/chat_event.dart';
import 'package:schat/features/chat_screen/src/presentation/bloc/chat_state.dart';
import 'package:schat/features/chat_socket_screen/src/domain/chat_socket_repository.dart';

class MockApiService extends Mock implements ApiService {}
class MockChatRepository extends Mock implements ChatRepository {}
class MockStorageService extends Mock implements StorageService {}
class MockChatSocketRepository extends Mock implements ChatSocketRepository {}

void main() {
  late ChatRepositoryImpl repository;
  late MockApiService mockApiService;

  setUp(() {
    mockApiService = MockApiService();
    repository = ChatRepositoryImpl(mockApiService);
  });

  group('ChatRepositoryImpl', () {
    test('sendMessage returns true', () async {
      final message = MessageModel(
        id: '99',
        conversationId: 'conv_1',
        senderId: 'me',
        content: 'Test message',
        isDeleted: false,
        createdAt: '2026-06-14T10:00:00Z',
        updatedAt: '2026-06-14T10:00:00Z',
      );
      final result = await repository.sendMessage(message);
      expect(result, isTrue);
    });
  });

  group('MessageModel', () {
    test('fromJson parses standard format', () {
      final json = {
        'id': '1',
        'conversationId': 'conv_123',
        'senderId': 'sender_123',
        'content': {
          'text': 'Hello world',
          'fileKey': null,
        },
        'type': 'text',
        'isDeleted': false,
        'createdAt': '2026-06-14T10:00:00Z',
        'updatedAt': '2026-06-14T10:00:00Z',
      };
      final message = MessageModel.fromJson(json);
      expect(message.id, '1');
      expect(message.content, 'Hello world');
      expect(message.createdAt, '2026-06-14T10:00:00Z');
    });

    test('fromJson parses epoch integer timestamps and nested content', () {
      final json = {
        'id': 'e18df892-5f9f-43a1-a8b2-0634af76ae52',
        'conversationId': '43607bc3-6877-41d7-8f84-fc4f418abb49',
        'senderId': 'f0482244-04a5-4140-b9fd-fe96e8d6851b',
        'receiverId': null,
        'type': 'text',
        'content': {
          'text': 'klk',
          'fileKey': null,
          'thumbnail': null,
        },
        'createdAt': 1781675775,
        'updatedAt': 1781675775,
      };
      final message = MessageModel.fromJson(json);
      expect(message.id, 'e18df892-5f9f-43a1-a8b2-0634af76ae52');
      expect(message.content, 'klk');
      expect(message.createdAt, '1781675775');
      expect(message.updatedAt, '1781675775');
    });
  });

  group('ChatMediaModel', () {
    test('fromJson parses API media completion format correctly', () {
      final json = {
        'id': 'bb06a1f0-7480-4a58-a56c-8ce603928349',
        'uploader_id': 'f0482244-04a5-4140-b9fd-fe96e8d6851b',
        'media_type': 'CHAT_IMAGE',
        'mime_type': 'image/png',
        'filename': 'string',
        'file_size_bytes': 10,
        'status': 'COMPLETED',
        'created_at': '2026-06-21T05:20:32.020297Z',
        'url': 'http://minio:9000/qlyncs-docs/chat-media/f0482244-04a5-4140-b9fd-fe96e8d6851b/3fa85f64-5717-4562-b3fc-2c963f66afa6/2026/06/bb06a1f0-7480-4a58-a56c-8ce603928349',
        'thumbnails': []
      };
      final media = ChatMediaModel.fromJson(json);
      expect(media.id, 'bb06a1f0-7480-4a58-a56c-8ce603928349');
      expect(media.uploaderId, 'f0482244-04a5-4140-b9fd-fe96e8d6851b');
      expect(media.mediaType, 'CHAT_IMAGE');
      expect(media.mimeType, 'image/png');
      expect(media.filename, 'string');
      expect(media.fileSizeBytes, 10);
      expect(media.status, 'COMPLETED');
      expect(media.createdAt, '2026-06-21T05:20:32.020297Z');
      expect(media.url, 'http://minio:9000/qlyncs-docs/chat-media/f0482244-04a5-4140-b9fd-fe96e8d6851b/3fa85f64-5717-4562-b3fc-2c963f66afa6/2026/06/bb06a1f0-7480-4a58-a56c-8ce603928349');
      expect(media.thumbnails, isEmpty);
    });
  });

  group('ChatBloc', () {
    late ChatBloc chatBloc;
    late MockChatRepository mockChatRepositoryInstance;
    late MockStorageService mockStorageService;
    late MockChatSocketRepository mockChatSocketRepository;

    setUp(() {
      Hive.init(Directory.systemTemp.path);
      mockChatRepositoryInstance = MockChatRepository();
      mockStorageService = MockStorageService();
      mockChatSocketRepository = MockChatSocketRepository();

      when(() => mockChatSocketRepository.onMessage).thenAnswer((_) => const Stream.empty());
      when(() => mockStorageService.getUserId()).thenReturn('me');

      chatBloc = ChatBloc(
        chatRepository: mockChatRepositoryInstance,
        storageService: mockStorageService,
        socketRepository: mockChatSocketRepository,
      );
    });

    tearDown(() {
      chatBloc.close();
    });

    test('ReceiveMessageEvent updates temporary message to real UUID if message is from self', () async {
      // First, simulate loading messages
      when(() => mockChatRepositoryInstance.getMessages('conv_1')).thenAnswer((_) async => []);
      chatBloc.add(const LoadMessagesEvent(conversationId: 'conv_1', recipientId: 'recipient_1'));
      await expectLater(chatBloc.stream, emitsThrough(isA<ChatLoaded>()));

      // Now add a temporary message (Send message)
      chatBloc.add(const SendMessageEvent(conversationId: 'conv_1', text: 'hello'));
      
      // Wait for ChatLoaded with the temporary message
      await expectLater(
        chatBloc.stream,
        emitsThrough(
          predicate<ChatState>((state) {
            if (state is ChatLoaded) {
              return state.messages.isNotEmpty && state.messages.first.id.startsWith('temp_');
            }
            return false;
          }),
        ),
      );

      // Now simulate receiving the broadcast of the same message from socket
      final broadcastJson = {
        'id': 'real-uuid-123',
        'conversationId': 'conv_1',
        'senderId': 'me',
        'content': {
          'text': 'hello',
          'fileKey': null,
        },
        'createdAt': '1781973234',
        'updatedAt': '1781973234',
      };
      
      chatBloc.add(ReceiveMessageEvent(messageData: broadcastJson));
      await expectLater(chatBloc.stream, emitsThrough(
        predicate<ChatState>((state) {
          if (state is ChatLoaded) {
            return state.messages.length == 1 && state.messages.first.id == 'real-uuid-123';
          }
          return false;
        })
      ));
    });
  });
}
