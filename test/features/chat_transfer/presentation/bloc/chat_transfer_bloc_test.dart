import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:schat/core/network/api_result.dart';
import 'package:schat/core/storage/storage_service.dart';
import 'package:schat/features/chat_socket_screen/src/domain/chat_socket_repository.dart';
import 'package:schat/features/chat_transfer_screen/src/domain/models/chat_view_request_model.dart';
import 'package:schat/features/chat_transfer_screen/src/domain/usecases/get_chat_view_requests_usecase.dart';
import 'package:schat/features/chat_transfer_screen/src/domain/usecases/get_target_conversations_usecase.dart';
import 'package:schat/features/chat_transfer_screen/src/domain/usecases/respond_chat_view_request_usecase.dart';
import 'package:schat/features/chat_transfer_screen/src/domain/usecases/revoke_chat_view_request_usecase.dart';
import 'package:schat/features/chat_transfer_screen/src/domain/usecases/send_chat_view_request_usecase.dart';
import 'package:schat/features/chat_transfer_screen/src/presentation/bloc/chat_transfer_bloc.dart';
import 'package:schat/features/chat_transfer_screen/src/presentation/bloc/chat_transfer_event.dart';
import 'package:schat/features/chat_transfer_screen/src/presentation/bloc/chat_transfer_state.dart';
import 'package:schat/features/dashboard_screen/src/domain/models/chat_model.dart';
import 'package:schat/features/dashboard_screen/src/domain/models/recipient_model.dart';

class MockStorageService extends Mock implements StorageService {}
class MockSendChatViewRequestUseCase extends Mock implements SendChatViewRequestUseCase {}
class MockGetChatViewRequestsUseCase extends Mock implements GetChatViewRequestsUseCase {}
class MockRespondChatViewRequestUseCase extends Mock implements RespondChatViewRequestUseCase {}
class MockRevokeChatViewRequestUseCase extends Mock implements RevokeChatViewRequestUseCase {}
class MockGetTargetConversationsUseCase extends Mock implements GetTargetConversationsUseCase {}
class MockChatSocketRepository extends Mock implements ChatSocketRepository {}

void main() {
  late MockStorageService mockStorageService;
  late MockSendChatViewRequestUseCase mockSendUseCase;
  late MockGetChatViewRequestsUseCase mockGetRequestsUseCase;
  late MockRespondChatViewRequestUseCase mockRespondUseCase;
  late MockRevokeChatViewRequestUseCase mockRevokeUseCase;
  late MockGetTargetConversationsUseCase mockGetTargetConversationsUseCase;
  late MockChatSocketRepository mockChatSocketRepository;
  late StreamController<dynamic> socketStreamController;

  setUp(() {
    mockStorageService = MockStorageService();
    mockSendUseCase = MockSendChatViewRequestUseCase();
    mockGetRequestsUseCase = MockGetChatViewRequestsUseCase();
    mockRespondUseCase = MockRespondChatViewRequestUseCase();
    mockRevokeUseCase = MockRevokeChatViewRequestUseCase();
    mockGetTargetConversationsUseCase = MockGetTargetConversationsUseCase();
    mockChatSocketRepository = MockChatSocketRepository();
    socketStreamController = StreamController<dynamic>.broadcast();

    when(() => mockChatSocketRepository.onMessage).thenAnswer((_) => socketStreamController.stream);
    when(() => mockStorageService.getUserId()).thenReturn('user-1');
  });

  tearDown(() {
    socketStreamController.close();
  });

  ChatTransferBloc buildBloc() {
    return ChatTransferBloc(
      mockStorageService,
      mockSendUseCase,
      mockGetRequestsUseCase,
      mockRespondUseCase,
      mockRevokeUseCase,
      mockGetTargetConversationsUseCase,
      mockChatSocketRepository,
    );
  }

  group('ChatTransferBloc', () {
    const mockRequest = ChatViewRequestModel(
      id: 'req-1',
      senderId: 'user-1',
      receiverId: 'user-2',
      status: 'pending',
    );

    blocTest<ChatTransferBloc, ChatTransferState>(
      'emits [loading, success] when LoadChatTransferData succeeds',
      build: () {
        when(() => mockGetRequestsUseCase.execute())
            .thenAnswer((_) async => ApiResult.success([mockRequest]));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const LoadChatTransferData()),
      expect: () => [
        const ChatTransferState(
          status: ChatTransferStatus.loading,
          currentUserId: 'user-1',
        ),
        const ChatTransferState(
          status: ChatTransferStatus.success,
          requests: [mockRequest],
          currentUserId: 'user-1',
        ),
      ],
    );

    blocTest<ChatTransferBloc, ChatTransferState>(
      'emits [loading, success] when SendChatTransferRequest succeeds',
      build: () {
        when(() => mockSendUseCase.execute(receiverId: 'user-2'))
            .thenAnswer((_) async => ApiResult.success(mockRequest));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const SendChatTransferRequest('user-2')),
      expect: () => [
        const ChatTransferState(
          status: ChatTransferStatus.loading,
        ),
        const ChatTransferState(
          status: ChatTransferStatus.success,
          requests: [mockRequest],
          successMessage: 'Chat view request sent successfully.',
        ),
      ],
    );

    blocTest<ChatTransferBloc, ChatTransferState>(
      'emits [loading, success] when RespondChatTransferRequest succeeds',
      seed: () => const ChatTransferState(requests: [mockRequest]),
      build: () {
        const acceptedRequest = ChatViewRequestModel(
          id: 'req-1',
          senderId: 'user-1',
          receiverId: 'user-2',
          status: 'accepted',
        );
        when(() => mockRespondUseCase.execute(requestId: 'req-1', accept: true))
            .thenAnswer((_) async => ApiResult.success(acceptedRequest));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const RespondChatTransferRequest(requestId: 'req-1', accept: true)),
      expect: () => [
        const ChatTransferState(
          status: ChatTransferStatus.loading,
          requests: [mockRequest],
        ),
        const ChatTransferState(
          status: ChatTransferStatus.success,
          requests: [
            ChatViewRequestModel(
              id: 'req-1',
              senderId: 'user-1',
              receiverId: 'user-2',
              status: 'accepted',
            ),
          ],
          successMessage: 'Request accepted.',
        ),
      ],
    );

    blocTest<ChatTransferBloc, ChatTransferState>(
      'emits [loading, success] when RevokeChatTransferRequest succeeds',
      seed: () => const ChatTransferState(requests: [mockRequest]),
      build: () {
        const revokedRequest = ChatViewRequestModel(
          id: 'req-1',
          senderId: 'user-1',
          receiverId: 'user-2',
          status: 'revoked',
        );
        when(() => mockRevokeUseCase.execute(requestId: 'req-1'))
            .thenAnswer((_) async => ApiResult.success(revokedRequest));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const RevokeChatTransferRequest('req-1')),
      expect: () => [
        const ChatTransferState(
          status: ChatTransferStatus.loading,
          requests: [mockRequest],
        ),
        const ChatTransferState(
          status: ChatTransferStatus.success,
          requests: [
            ChatViewRequestModel(
              id: 'req-1',
              senderId: 'user-1',
              receiverId: 'user-2',
              status: 'revoked',
            ),
          ],
          successMessage: 'Access revoked successfully.',
        ),
      ],
    );

    blocTest<ChatTransferBloc, ChatTransferState>(
      'emits [loading, success] when LoadTargetConversations succeeds',
      build: () {
        const chat = ChatModel(id: 'c1', recipient: RecipientModel());
        when(() => mockGetTargetConversationsUseCase.execute(targetUserId: 'user-2'))
            .thenAnswer((_) async => ApiResult.success([chat]));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const LoadTargetConversations(targetUserId: 'user-2')),
      expect: () => [
        const ChatTransferState(
          status: ChatTransferStatus.loading,
        ),
        const ChatTransferState(
          status: ChatTransferStatus.success,
          monitoredConversations: [
            ChatModel(id: 'c1', recipient: RecipientModel()),
          ],
        ),
      ],
    );
  });
}
