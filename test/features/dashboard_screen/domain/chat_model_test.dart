import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:schat/features/dashboard_screen/src/domain/models/chat_model.dart';

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

  test('should parse ChatModel with map-based content, integer timestamps, and camelCase keys in last_message', () {
    const rawJson = '''
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
        "subscription_type": "Silver",
        "created_at": "2026-06-13T12:04:16.410730Z",
        "updated_at": "2026-06-14T08:05:26.278700Z"
      },
      "last_message": {
        "id": "e18df892-5f9f-43a1-a8b2-0634af76ae52",
        "conversationId": "43607bc3-6877-41d7-8f84-fc4f418abb49",
        "senderId": "f0482244-04a5-4140-b9fd-fe96e8d6851b",
        "receiverId": null,
        "type": "text",
        "content": {
          "text": "klk",
          "fileKey": null,
          "thumbnail": null,
          "fileName": null,
          "fileSize": null,
          "mimeType": null,
          "duration": null
        },
        "security": {
          "isLocked": false,
          "accessUsers": [],
          "allowDownload": true,
          "allowShare": true
        },
        "viewControl": {
          "type": "normal",
          "maxViews": 1,
          "viewedBy": [],
          "isOpened": false,
          "openedAt": null
        },
        "expiry": {
          "isEnabled": false,
          "expireType": null,
          "expireAt": null
        },
        "callMeta": {
          "callType": null,
          "duration": null,
          "status": null
        },
        "isReply": false,
        "replyMessageId": null,
        "replyMessageBody": null,
        "userView": null,
        "deletedFor": [],
        "isDeletedForEveryone": false,
        "createdAt": 1781675775,
        "updatedAt": 1781675775
      }
    }
    ''';

    final Map<String, dynamic> jsonMap = json.decode(rawJson);
    final chatModel = ChatModel.fromJson(jsonMap);

    expect(chatModel.lastMessage?.conversationId, '43607bc3-6877-41d7-8f84-fc4f418abb49');
    expect(chatModel.lastMessage?.senderId, 'f0482244-04a5-4140-b9fd-fe96e8d6851b');
    expect(chatModel.lastMessage?.content, 'klk');
    expect(chatModel.lastMessage?.createdAt, '1781675775');
    expect(chatModel.lastMessage?.updatedAt, '1781675775');
  });

  test('should parse exact user JSON response payload', () {
    const userJson = r'''
{
  "conversations": [
    {
      "id": "2892d398-752a-49a6-be99-8622a5156204",
      "is_group": false,
      "group_name": null,
      "group_description": null,
      "is_favorite": false,
      "is_muted": false,
      "isHidden": false,
      "isHided": false,
      "disappearing_timer": null,
      "themeColor": null,
      "created_at": "2026-06-18T05:42:15.778324Z",
      "updated_at": "2026-07-02T13:44:25.164752Z",
      "recipient": {
        "phone_number": "9030303983",
        "username": "siva kumar &-++_f__-+",
        "first_name": "",
        "last_name": "",
        "profile_picture_url": "https://qlyncs-docs.s3.amazonaws.com/chat-media/f0482244-04a5-4140-b9fd-fe96e8d6851b/f0482244-04a5-4140-b9fd-fe96e8d6851b/2026/07/c50d4fe6-ccec-48ed-90e6-0abcec229fb8.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAY4Z3D5EZF4NQQIE4%2F20260702%2Fap-south-1%2Fs3%2Faws4_request&X-Amz-Date=20260702T171207Z&X-Amz-Expires=3600&X-Amz-SignedHeaders=host&X-Amz-Signature=ff4da95727d51e13b7ddf9d8fd5b9c83570889b11a8df85406c03947c0be9b8e",
        "about": "",
        "id": "f0482244-04a5-4140-b9fd-fe96e8d6851b",
        "is_active": true,
        "is_online": false,
        "last_seen": null,
        "is_subscribed": true,
        "subscription_type": "Platinum",
        "theme_preference": "system",
        "notifications_enabled": true,
        "defaultDisappearingTimer": null,
        "created_at": "2026-06-12T04:49:15.010740Z",
        "updated_at": "2026-07-01T19:02:46.935632Z"
      },
      "last_message": {
        "id": "2b44c7a4-ab34-4a83-a20a-a127273340c4",
        "conversationId": "2892d398-752a-49a6-be99-8622a5156204",
        "senderId": "f0482244-04a5-4140-b9fd-fe96e8d6851b",
        "receiverId": null,
        "type": "call",
        "content": {
          "text": null,
          "fileKey": null,
          "thumbnail": null,
          "fileName": null,
          "fileSize": null,
          "mimeType": null,
          "duration": null,
          "isForwarded": null,
          "forwardedFromMessageId": null,
          "forwardCount": null,
          "contactName": null,
          "phoneNumber": null,
          "latitude": null,
          "longitude": null,
          "address": null
        },
        "security": {
          "isLocked": false,
          "accessUsers": [],
          "allowDownload": true,
          "allowShare": true
        },
        "viewControl": {
          "type": "normal",
          "maxViews": 1,
          "viewedBy": [],
          "isOpened": false,
          "openedAt": null
        },
        "expiry": {
          "isEnabled": false,
          "expireType": null,
          "expireAt": null,
          "disappearAfterRead": false,
          "readTimerSeconds": null
        },
        "callMeta": {
          "callType": "video",
          "duration": 0,
          "status": "reject"
        },
        "isReply": false,
        "replyMessageId": null,
        "replyMessageBody": null,
        "isPinned": false,
        "pinnedAt": null,
        "userView": null,
        "deletedFor": [],
        "isDeletedForEveryone": false,
        "createdAt": 1783010813,
        "updatedAt": 1783010828
      }
    },
    {
      "id": "4150affa-c203-495b-a899-d149a5e98c4d",
      "is_group": true,
      "group_name": "mvbxcmv",
      "group_description": "",
      "is_favorite": false,
      "is_muted": false,
      "isHidden": false,
      "isHided": false,
      "disappearing_timer": null,
      "themeColor": null,
      "created_at": "2026-06-29T12:43:39.100336Z",
      "updated_at": "2026-06-30T16:27:46.991460Z",
      "recipient": null,
      "last_message": {
        "id": "1bc96906-2501-4997-b2f6-984717aede4d",
        "conversationId": "4150affa-c203-495b-a899-d149a5e98c4d",
        "senderId": "3e362d19-aa0b-44b1-a318-f34b3b3efc2c",
        "receiverId": null,
        "type": "call",
        "content": {
          "text": null,
          "fileKey": null,
          "thumbnail": null,
          "fileName": null,
          "fileSize": null,
          "mimeType": null,
          "duration": null,
          "isForwarded": null,
          "forwardedFromMessageId": null,
          "forwardCount": null,
          "contactName": null,
          "phoneNumber": null,
          "latitude": null,
          "longitude": null,
          "address": null
        },
        "security": {
          "isLocked": false,
          "accessUsers": [],
          "allowDownload": true,
          "allowShare": true
        },
        "viewControl": {
          "type": "normal",
          "maxViews": 1,
          "viewedBy": [],
          "isOpened": false,
          "openedAt": null
        },
        "expiry": {
          "isEnabled": false,
          "expireType": null,
          "expireAt": null,
          "disappearAfterRead": false,
          "readTimerSeconds": null
        },
        "callMeta": {
          "callType": "audio",
          "duration": 0,
          "status": "missed"
        },
        "isReply": false,
        "replyMessageId": null,
        "replyMessageBody": null,
        "isPinned": false,
        "pinnedAt": null,
        "userView": null,
        "deletedFor": [],
        "isDeletedForEveryone": false,
        "createdAt": 1783003328,
        "updatedAt": 1783003328
      }
    },
    {
      "id": "027b50a8-cb33-41c1-8943-a171206c24b9",
      "is_group": false,
      "group_name": null,
      "group_description": null,
      "is_favorite": false,
      "is_muted": false,
      "isHidden": false,
      "isHided": false,
      "disappearing_timer": null,
      "themeColor": null,
      "created_at": "2026-06-30T06:11:36.484510Z",
      "updated_at": "2026-06-30T08:05:44.594029Z",
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
        "subscription_type": "Silver",
        "theme_preference": "system",
        "notifications_enabled": true,
        "defaultDisappearingTimer": null,
        "created_at": "2026-06-13T12:04:16.410730Z",
        "updated_at": "2026-06-14T08:05:26.278700Z"
      },
      "last_message": {
        "id": "36cf9929-267f-471c-b77f-0659d6708ada",
        "conversationId": "027b50a8-cb33-41c1-8943-a171206c24b9",
        "senderId": "7edd708a-3262-42c4-abc7-51340328190c",
        "receiverId": null,
        "type": "text",
        "content": {
          "text": null,
          "fileKey": null,
          "thumbnail": null,
          "fileName": null,
          "fileSize": null,
          "mimeType": null,
          "duration": null,
          "isForwarded": null,
          "forwardedFromMessageId": null,
          "forwardCount": null,
          "contactName": null,
          "phoneNumber": null,
          "latitude": null,
          "longitude": null,
          "address": null
        },
        "security": {
          "isLocked": false,
          "accessUsers": [],
          "allowDownload": true,
          "allowShare": true
        },
        "viewControl": {
          "type": "normal",
          "maxViews": 1,
          "viewedBy": [],
          "isOpened": false,
          "openedAt": null
        },
        "expiry": {
          "isEnabled": false,
          "expireType": null,
          "expireAt": null,
          "disappearAfterRead": false,
          "readTimerSeconds": null
        },
        "callMeta": {
          "callType": null,
          "duration": null,
          "status": null
        },
        "isReply": false,
        "replyMessageId": null,
        "replyMessageBody": null,
        "isPinned": false,
        "pinnedAt": null,
        "userView": null,
        "deletedFor": [],
        "isDeletedForEveryone": false,
        "createdAt": 1782806744,
        "updatedAt": 1782806744
      }
    },
    {
      "id": "a690e3c4-4059-4377-bb4b-1f13856421c2",
      "is_group": true,
      "group_name": "siva test",
      "group_description": "hello",
      "is_favorite": false,
      "is_muted": false,
      "isHidden": false,
      "isHided": false,
      "disappearing_timer": null,
      "themeColor": null,
      "created_at": "2026-06-23T15:59:40.748728Z",
      "updated_at": "2026-06-23T15:59:40.748732Z",
      "recipient": null,
      "last_message": null
    }
  ],
  "hiddenConversations": [
    {
      "id": "4469cb96-6cb1-478c-826d-f96852589cbc",
      "is_group": false,
      "group_name": null,
      "group_description": null,
      "is_favorite": false,
      "is_muted": false,
      "isHidden": true,
      "isHided": true,
      "disappearing_timer": null,
      "themeColor": null,
      "created_at": "2026-06-18T06:05:07.644323Z",
      "updated_at": "2026-07-02T16:29:21.019080Z",
      "recipient": {
        "phone_number": "8008038682",
        "username": "maha lakshmi",
        "first_name": null,
        "last_name": null,
        "profile_picture_url": null,
        "about": null,
        "id": "bea03838-949f-4e1d-a0aa-ddd487f1ea90",
        "is_active": true,
        "is_online": false,
        "last_seen": null,
        "is_subscribed": true,
        "subscription_type": "Business",
        "theme_preference": "system",
        "notifications_enabled": true,
        "defaultDisappearingTimer": null,
        "created_at": "2026-06-18T05:25:30.608190Z",
        "updated_at": "2026-06-18T05:26:02.236374Z"
      },
      "last_message": {
        "id": "4b06e3be-d277-42d5-a170-d6f1911f5bb6",
        "conversationId": "4469cb96-6cb1-478c-826d-f96852589cbc",
        "senderId": "3e362d19-aa0b-44b1-a318-f34b3b3efc2c",
        "receiverId": null,
        "type": "text",
        "content": {
          "text": "hello",
          "fileKey": null,
          "thumbnail": null,
          "fileName": null,
          "fileSize": null,
          "mimeType": null,
          "duration": null,
          "isForwarded": null,
          "forwardedFromMessageId": null,
          "forwardCount": null,
          "contactName": null,
          "phoneNumber": null,
          "latitude": null,
          "longitude": null,
          "address": null
        },
        "security": {
          "isLocked": false,
          "accessUsers": [],
          "allowDownload": true,
          "allowShare": true
        },
        "viewControl": {
          "type": "normal",
          "maxViews": 1,
          "viewedBy": [],
          "isOpened": false,
          "openedAt": null
        },
        "expiry": {
          "isEnabled": false,
          "expireType": null,
          "expireAt": null,
          "disappearAfterRead": false,
          "readTimerSeconds": null
        },
        "callMeta": {
          "callType": null,
          "duration": null,
          "status": null
        },
        "isReply": false,
        "replyMessageId": null,
        "replyMessageBody": null,
        "isPinned": false,
        "pinnedAt": null,
        "userView": null,
        "deletedFor": [],
        "isDeletedForEveryone": false,
        "createdAt": 1783009761,
        "updatedAt": 1783009761
      }
    },
    {
      "id": "1a34ad27-31d1-41ad-b19d-58b61464f99b",
      "is_group": true,
      "group_name": "siva test",
      "group_description": "hello",
      "is_favorite": false,
      "is_muted": false,
      "isHidden": true,
      "isHided": true,
      "disappearing_timer": null,
      "themeColor": null,
      "created_at": "2026-06-23T16:00:50.457142Z",
      "updated_at": "2026-06-23T16:00:50.457147Z",
      "recipient": null,
      "last_message": null
    }
  ],
  "hidedConversations": [
    {
      "id": "4469cb96-6cb1-478c-826d-f96852589cbc",
      "is_group": false,
      "group_name": null,
      "group_description": null,
      "is_favorite": false,
      "is_muted": false,
      "isHidden": true,
      "isHided": true,
      "disappearing_timer": null,
      "themeColor": null,
      "created_at": "2026-06-18T06:05:07.644323Z",
      "updated_at": "2026-07-02T16:29:21.019080Z",
      "recipient": {
        "phone_number": "8008038682",
        "username": "maha lakshmi",
        "first_name": null,
        "last_name": null,
        "profile_picture_url": null,
        "about": null,
        "id": "bea03838-949f-4e1d-a0aa-ddd487f1ea90",
        "is_active": true,
        "is_online": false,
        "last_seen": null,
        "is_subscribed": true,
        "subscription_type": "Business",
        "theme_preference": "system",
        "notifications_enabled": true,
        "defaultDisappearingTimer": null,
        "created_at": "2026-06-18T05:25:30.608190Z",
        "updated_at": "2026-06-18T05:26:02.236374Z"
      },
      "last_message": {
        "id": "4b06e3be-d277-42d5-a170-d6f1911f5bb6",
        "conversationId": "4469cb96-6cb1-478c-826d-f96852589cbc",
        "senderId": "3e362d19-aa0b-44b1-a318-f34b3b3efc2c",
        "receiverId": null,
        "type": "text",
        "content": {
          "text": "hello",
          "fileKey": null,
          "thumbnail": null,
          "fileName": null,
          "fileSize": null,
          "mimeType": null,
          "duration": null,
          "isForwarded": null,
          "forwardedFromMessageId": null,
          "forwardCount": null,
          "contactName": null,
          "phoneNumber": null,
          "latitude": null,
          "longitude": null,
          "address": null
        },
        "security": {
          "isLocked": false,
          "accessUsers": [],
          "allowDownload": true,
          "allowShare": true
        },
        "viewControl": {
          "type": "normal",
          "maxViews": 1,
          "viewedBy": [],
          "isOpened": false,
          "openedAt": null
        },
        "expiry": {
          "isEnabled": false,
          "expireType": null,
          "expireAt": null,
          "disappearAfterRead": false,
          "readTimerSeconds": null
        },
        "callMeta": {
          "callType": null,
          "duration": null,
          "status": null
        },
        "isReply": false,
        "replyMessageId": null,
        "replyMessageBody": null,
        "isPinned": false,
        "pinnedAt": null,
        "userView": null,
        "deletedFor": [],
        "isDeletedForEveryone": false,
        "createdAt": 1783009761,
        "updatedAt": 1783009761
      }
    },
    {
      "id": "1a34ad27-31d1-41ad-b19d-58b61464f99b",
      "is_group": true,
      "group_name": "siva test",
      "group_description": "hello",
      "is_favorite": false,
      "is_muted": false,
      "isHidden": true,
      "isHided": true,
      "disappearing_timer": null,
      "themeColor": null,
      "created_at": "2026-06-23T16:00:50.457142Z",
      "updated_at": "2026-06-23T16:00:50.457147Z",
      "recipient": null,
      "last_message": null
    }
  ]
}
    ''';
    
    final Map<String, dynamic> jsonMap = json.decode(userJson);
    final conversations = jsonMap['conversations'] as List;
    final hiddenConversations = jsonMap['hiddenConversations'] as List;
    
    final parsedConversations = conversations.map((e) => ChatModel.fromJson(Map<String, dynamic>.from(e))).toList();
    final parsedHidden = hiddenConversations.map((e) => ChatModel.fromJson(Map<String, dynamic>.from(e))).toList();
    
    expect(parsedConversations.length, 4);
    expect(parsedHidden.length, 2);
    expect(parsedHidden[0].isHidden, true);
    expect(parsedHidden[0].isHided, true);
    expect(parsedHidden[1].isGroup, true);
    expect(parsedHidden[1].recipient.id, '');
  });
}

