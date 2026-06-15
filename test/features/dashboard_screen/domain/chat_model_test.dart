import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:schat/features/dashboard_screen/src/domain/chat_model.dart';

void main() {
  const jsonResponse = '''
  {
    "id": "43607bc3-6877-41d7-8f84-fc4f418abb49",
    "is_group": false,
    "group_name": null,
    "group_description": null,
    "created_at": "2026-06-13T12:15:20.836912Z",
    "updated_at": "2026-06-13T12:15:20.836916Z",
    "recipient": {
      "phone_number": "7670844837",
      "username": "Puja Sri",
      "first_name": null,
      "last_name": null,
      "profile_picture_url": "https://plus.unsplash.com/premium_photo-1682089810582-f7b200217b67?q=80&w=987&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D",
      "about": null,
      "id": "7edd708a-3262-42c4-abc7-51340328190c",
      "is_active": true,
      "is_online": false,
      "last_seen": null,
      "is_subscribed": true,
      "created_at": "2026-06-13T12:04:16.410730Z",
      "updated_at": "2026-06-14T08:05:26.278700Z"
    },
    "last_message": {
      "id": "d1ed36c8-1963-4a57-a553-f03aa1fdb478",
      "conversation_id": "43607bc3-6877-41d7-8f84-fc4f418abb49",
      "sender_id": "7edd708a-3262-42c4-abc7-51340328190c",
      "content": "Bbbb",
      "media_url": null,
      "media_type": null,
      "is_deleted": false,
      "created_at": "2026-06-14T11:46:35.328524Z",
      "updated_at": "2026-06-14T11:46:35.328524Z"
    }
  }
  ''';

  test('should parse ChatModel from updated API JSON response', () {
    final Map<String, dynamic> jsonMap = json.decode(jsonResponse);
    final chatModel = ChatModel.fromJson(jsonMap);

    expect(chatModel.id, '43607bc3-6877-41d7-8f84-fc4f418abb49');
    expect(chatModel.isGroup, false);
    expect(chatModel.recipient.username, 'Puja Sri');
    expect(chatModel.recipient.phoneNumber, '7670844837');
    expect(chatModel.lastMessage?.content, 'Bbbb');
    expect(chatModel.lastMessage?.isDeleted, false);
  });

  test('should parse ChatModel with null last_message', () {
    final jsonMap = json.decode(jsonResponse) as Map<String, dynamic>;
    jsonMap['last_message'] = null;
    
    final chatModel = ChatModel.fromJson(jsonMap);
    
    expect(chatModel.lastMessage, isNull);
  });
}
