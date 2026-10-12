import 'package:flutter_test/flutter_test.dart';
import 'package:schat/features/chat_screen/src/domain/models/message_model.dart';
import 'package:schat/features/chat_screen/src/presentation/bloc/chat_event.dart';

void main() {
  group('File Sharing Access Control - Frontend Acceptance Tests', () {
    test('MessageModel properly parses effective permissions from attachment payload', () {
      final json = {
        'id': 'msg_100',
        'conversation_id': 'conv_1',
        'sender_id': 'user_a',
        'type': 'image',
        'isDeleted': false,
        'attachment': {
          'media_id': 'file_x_123',
          'url': 'https://s3.example.com/file_x.jpg',
          'security': {
            'can_view': true,
            'can_download': true,
            'can_share': true,
          },
        },
      };

      final message = MessageModel.fromJson(json);

      expect(message.allowView, isTrue);
      expect(message.allowDownload, isTrue);
      expect(message.allowShare, isTrue);
      expect(message.mediaUrl, equals('https://s3.example.com/file_x.jpg'));
    });

    test('MessageModel reflects revoked permissions disabling View, Download, and Share', () {
      final json = {
        'id': 'msg_101',
        'conversation_id': 'conv_1',
        'sender_id': 'user_a',
        'type': 'image',
        'isDeleted': false,
        'attachment': {
          'media_id': 'file_x_123',
          'security': {
            'can_view': false,
            'can_download': false,
            'can_share': false,
          },
        },
      };

      final message = MessageModel.fromJson(json);

      expect(message.allowView, isFalse);
      expect(message.allowDownload, isFalse);
      expect(message.allowShare, isFalse);
    });

    test('ReceiveMediaPermissionsUpdatedEvent correctly models revoked payload', () {
      const event = ReceiveMediaPermissionsUpdatedEvent(
        mediaId: 'file_x_123',
        allowShare: false,
        allowDownload: false,
        allowView: false,
        isRevoked: true,
      );

      expect(event.isRevoked, isTrue);
      expect(event.allowView, isFalse);
      expect(event.allowDownload, isFalse);
      expect(event.allowShare, isFalse);
      expect(event.mediaId, equals('file_x_123'));
    });

    test('MessageModel copyWith correctly cascades revoked permission update', () {
      final initialMessage = MessageModel.fromJson({
        'id': 'msg_102',
        'conversation_id': 'conv_1',
        'sender_id': 'user_b',
        'type': 'image',
        'isDeleted': false,
        'media_url': 'https://s3.example.com/file_x.jpg',
        'security': {
          'can_view': true,
          'can_download': true,
          'can_share': true,
        },
      });

      expect(initialMessage.allowView, isTrue);
      expect(initialMessage.allowDownload, isTrue);
      expect(initialMessage.allowShare, isTrue);

      // Simulate cascading revocation applied by ChatBloc
      final updatedMessage = initialMessage.copyWith(
        allowView: false,
        allowDownload: false,
        allowShare: false,
      );

      expect(updatedMessage.allowView, isFalse);
      expect(updatedMessage.allowDownload, isFalse);
      expect(updatedMessage.allowShare, isFalse);
    });

    test('Initial share person message has isForwarded=false and isInitialShare=true', () {
      final json = {
        'id': 'msg_initial_1',
        'conversation_id': 'conv_1',
        'sender_id': 'user_a',
        'type': 'image',
        'isDeleted': false,
        'content': {
          'fileKey': 'https://s3.example.com/file_x.jpg',
          'isForwarded': false,
        },
      };

      final message = MessageModel.fromJson(json);

      expect(message.isForwarded, isFalse);
      expect(message.isInitialShare, isTrue);
      expect(message.forwardedFromMessageId, isNull);

      // Verify share details visibility logic
      const bool isMe = true;
      const bool isGroup = false;
      final bool isMedia = message.messageType == 'image';
      final bool showShareDetails = isMe && !isGroup && isMedia && message.allowView && !message.isForwarded;
      expect(showShareDetails, isTrue);
    });

    test('Downstream share person (forwarded message) has isForwarded=true and isInitialShare=false', () {
      final json = {
        'id': 'msg_forwarded_1',
        'conversation_id': 'conv_2',
        'sender_id': 'user_b',
        'type': 'image',
        'isDeleted': false,
        'content': {
          'fileKey': 'https://s3.example.com/file_x.jpg',
          'isForwarded': true,
          'forwardedFromMessageId': 'msg_initial_1',
        },
      };

      final message = MessageModel.fromJson(json);

      expect(message.isForwarded, isTrue);
      expect(message.isInitialShare, isFalse);
      expect(message.forwardedFromMessageId, equals('msg_initial_1'));

      // Even though isMe=true for user B in conv_2, showShareDetails MUST BE false for downstream sharer
      const bool isMe = true;
      const bool isGroup = false;
      final bool isMedia = message.messageType == 'image';
      final bool showShareDetails = isMe && !isGroup && isMedia && message.allowView && !message.isForwarded;
      expect(showShareDetails, isFalse, reason: 'Other share person must not see show share details button');
    });
  });
}
