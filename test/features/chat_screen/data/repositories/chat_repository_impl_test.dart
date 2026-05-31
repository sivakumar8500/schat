import 'package:flutter_test/flutter_test.dart';
import 'package:schat/features/chat_screen/src/data/repositories/chat_repository_impl.dart';
import 'package:schat/features/chat_screen/src/domain/models/message_model.dart';

void main() {
  late ChatRepositoryImpl repository;

  setUp(() {
    repository = ChatRepositoryImpl();
  });

  group('ChatRepositoryImpl', () {
    test('getMessages returns list of messages', () async {
      final messages = await repository.getMessages('Alice');
      expect(messages, isNotEmpty);
      expect(messages.first.text, 'Hey! How are you doing today?');
    });

    test('sendMessage returns true', () async {
      final message = MessageModel(
        id: '99',
        text: 'Test message',
        time: 'Just now',
        isMe: true,
      );
      final result = await repository.sendMessage(message);
      expect(result, isTrue);
    });
  });
}
