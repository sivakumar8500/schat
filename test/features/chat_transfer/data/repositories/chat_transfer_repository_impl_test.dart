import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:schat/core/network/api_service.dart';
import 'package:schat/features/chat_transfer_screen/src/data/repositories/chat_transfer_repository_impl.dart';
import 'package:schat/utils/common_endpoints.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late ChatTransferRepositoryImpl repository;
  late MockDio mockDio;
  late ApiService apiService;

  setUp(() {
    mockDio = MockDio();
    apiService = ApiService(mockDio);
    repository = ChatTransferRepositoryImpl(apiService);
  });

  group('ChatTransferRepositoryImpl', () {
    test('sendChatViewRequest returns success ChatViewRequestModel', () async {
      final mockData = {
        'id': 'req-123',
        'senderId': 'user-1',
        'receiverId': 'user-2',
        'status': 'pending',
        'sender': {'id': 'user-1', 'username': 'parent_alex'},
        'receiver': {'id': 'user-2', 'username': 'child_sam'},
        'createdAt': '2026-09-23T10:00:00Z',
      };

      when(
        () => mockDio.request(
          CommonEndpoints.chatViewRequests,
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: mockData,
          statusCode: 200,
          requestOptions: RequestOptions(path: CommonEndpoints.chatViewRequests),
        ),
      );

      final result = await repository.sendChatViewRequest(receiverId: 'user-2');

      result.when(
        success: (request) {
          expect(request.id, 'req-123');
          expect(request.senderId, 'user-1');
          expect(request.receiverId, 'user-2');
          expect(request.status, 'pending');
        },
        failure: (error, statusCode) => fail('Should have succeeded: $error'),
      );
    });

    test('getChatViewRequests returns list of requests', () async {
      final mockList = [
        {
          'id': 'req-1',
          'senderId': 'user-1',
          'receiverId': 'user-2',
          'status': 'accepted',
        },
        {
          'id': 'req-2',
          'senderId': 'user-3',
          'receiverId': 'user-1',
          'status': 'pending',
        },
      ];

      when(
        () => mockDio.request(
          CommonEndpoints.chatViewRequests,
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: mockList,
          statusCode: 200,
          requestOptions: RequestOptions(path: CommonEndpoints.chatViewRequests),
        ),
      );

      final result = await repository.getChatViewRequests();

      result.when(
        success: (requests) {
          expect(requests.length, 2);
          expect(requests.first.id, 'req-1');
          expect(requests.first.status, 'accepted');
        },
        failure: (error, statusCode) => fail('Should have succeeded: $error'),
      );
    });

    test('respondChatViewRequest returns updated request model', () async {
      final mockData = {
        'id': 'req-1',
        'senderId': 'user-1',
        'receiverId': 'user-2',
        'status': 'accepted',
      };

      when(
        () => mockDio.request(
          CommonEndpoints.respondChatViewRequest('req-1'),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: mockData,
          statusCode: 200,
          requestOptions: RequestOptions(path: CommonEndpoints.respondChatViewRequest('req-1')),
        ),
      );

      final result = await repository.respondChatViewRequest(requestId: 'req-1', accept: true);

      result.when(
        success: (req) {
          expect(req.id, 'req-1');
          expect(req.status, 'accepted');
        },
        failure: (error, statusCode) => fail('Should have succeeded: $error'),
      );
    });

    test('revokeChatViewRequest returns revoked request model', () async {
      final mockData = {
        'id': 'req-1',
        'senderId': 'user-1',
        'receiverId': 'user-2',
        'status': 'revoked',
      };

      when(
        () => mockDio.request(
          CommonEndpoints.revokeChatViewRequest('req-1'),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: mockData,
          statusCode: 200,
          requestOptions: RequestOptions(path: CommonEndpoints.revokeChatViewRequest('req-1')),
        ),
      );

      final result = await repository.revokeChatViewRequest(requestId: 'req-1');

      result.when(
        success: (req) {
          expect(req.id, 'req-1');
          expect(req.status, 'revoked');
        },
        failure: (error, statusCode) => fail('Should have succeeded: $error'),
      );
    });

    test('getTargetConversations returns conversation list', () async {
      final mockData = {
        'conversations': [
          {
            '_id': 'conv-1',
            'is_group': false,
            'recipient': {
              'id': 'rec-1',
              'name': 'Charlie',
            },
          }
        ]
      };

      when(
        () => mockDio.request(
          CommonEndpoints.getTargetConversations('user-2'),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: mockData,
          statusCode: 200,
          requestOptions: RequestOptions(path: CommonEndpoints.getTargetConversations('user-2')),
        ),
      );

      final result = await repository.getTargetConversations(targetUserId: 'user-2');

      result.when(
        success: (chats) {
          expect(chats.length, 1);
          expect(chats.first.id, 'conv-1');
        },
        failure: (error, statusCode) => fail('Should have succeeded: $error'),
      );
    });
  });
}
