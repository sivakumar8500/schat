import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:schat/core/network/api_service.dart';
import 'package:schat/features/chat_screen/src/data/repositories/chat_repository_impl.dart';
import 'package:schat/features/chat_screen/src/domain/models/message_model.dart';

class MockApiService extends Mock implements ApiService {}

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
}
