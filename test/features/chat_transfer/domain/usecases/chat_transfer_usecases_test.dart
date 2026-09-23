import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:schat/core/network/api_result.dart';
import 'package:schat/features/chat_transfer_screen/src/domain/models/chat_view_request_model.dart';
import 'package:schat/features/chat_transfer_screen/src/domain/repositories/chat_transfer_repository.dart';
import 'package:schat/features/chat_transfer_screen/src/domain/usecases/get_chat_view_requests_usecase.dart';
import 'package:schat/features/chat_transfer_screen/src/domain/usecases/get_target_conversations_usecase.dart';
import 'package:schat/features/chat_transfer_screen/src/domain/usecases/respond_chat_view_request_usecase.dart';
import 'package:schat/features/chat_transfer_screen/src/domain/usecases/revoke_chat_view_request_usecase.dart';
import 'package:schat/features/chat_transfer_screen/src/domain/usecases/send_chat_view_request_usecase.dart';
import 'package:schat/features/dashboard_screen/src/domain/models/chat_model.dart';
import 'package:schat/features/dashboard_screen/src/domain/models/recipient_model.dart';

class MockChatTransferRepository extends Mock implements ChatTransferRepository {}

void main() {
  late MockChatTransferRepository repository;
  late SendChatViewRequestUseCase sendUseCase;
  late GetChatViewRequestsUseCase getRequestsUseCase;
  late RespondChatViewRequestUseCase respondUseCase;
  late RevokeChatViewRequestUseCase revokeUseCase;
  late GetTargetConversationsUseCase getTargetConversationsUseCase;

  setUp(() {
    repository = MockChatTransferRepository();
    sendUseCase = SendChatViewRequestUseCase(repository);
    getRequestsUseCase = GetChatViewRequestsUseCase(repository);
    respondUseCase = RespondChatViewRequestUseCase(repository);
    revokeUseCase = RevokeChatViewRequestUseCase(repository);
    getTargetConversationsUseCase = GetTargetConversationsUseCase(repository);
  });

  group('ChatTransfer UseCases', () {
    test('SendChatViewRequestUseCase executes repository method', () async {
      const mockReq = ChatViewRequestModel(id: '1', senderId: 'u1', receiverId: 'u2', status: 'pending');
      when(() => repository.sendChatViewRequest(receiverId: 'u2'))
          .thenAnswer((_) async => ApiResult.success(mockReq));

      final result = await sendUseCase.execute(receiverId: 'u2');

      result.when(
        success: (req) => expect(req.id, '1'),
        failure: (e, s) => fail('Should succeed'),
      );
      verify(() => repository.sendChatViewRequest(receiverId: 'u2')).called(1);
    });

    test('GetChatViewRequestsUseCase executes repository method', () async {
      when(() => repository.getChatViewRequests())
          .thenAnswer((_) async => ApiResult.success([]));

      final result = await getRequestsUseCase.execute();

      result.when(
        success: (list) => expect(list, isEmpty),
        failure: (e, s) => fail('Should succeed'),
      );
      verify(() => repository.getChatViewRequests()).called(1);
    });

    test('RespondChatViewRequestUseCase executes repository method', () async {
      const mockReq = ChatViewRequestModel(id: '1', status: 'accepted');
      when(() => repository.respondChatViewRequest(requestId: '1', accept: true))
          .thenAnswer((_) async => ApiResult.success(mockReq));

      final result = await respondUseCase.execute(requestId: '1', accept: true);

      result.when(
        success: (req) => expect(req.status, 'accepted'),
        failure: (e, s) => fail('Should succeed'),
      );
      verify(() => repository.respondChatViewRequest(requestId: '1', accept: true)).called(1);
    });

    test('RevokeChatViewRequestUseCase executes repository method', () async {
      const mockReq = ChatViewRequestModel(id: '1', status: 'revoked');
      when(() => repository.revokeChatViewRequest(requestId: '1'))
          .thenAnswer((_) async => ApiResult.success(mockReq));

      final result = await revokeUseCase.execute(requestId: '1');

      result.when(
        success: (req) => expect(req.status, 'revoked'),
        failure: (e, s) => fail('Should succeed'),
      );
      verify(() => repository.revokeChatViewRequest(requestId: '1')).called(1);
    });

    test('GetTargetConversationsUseCase executes repository method', () async {
      const mockChat = ChatModel(id: 'c1', recipient: RecipientModel());
      when(() => repository.getTargetConversations(targetUserId: 'u2'))
          .thenAnswer((_) async => ApiResult.success([mockChat]));

      final result = await getTargetConversationsUseCase.execute(targetUserId: 'u2');

      result.when(
        success: (chats) => expect(chats.length, 1),
        failure: (e, s) => fail('Should succeed'),
      );
      verify(() => repository.getTargetConversations(targetUserId: 'u2')).called(1);
    });
  });
}
