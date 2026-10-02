class GlobalSearchResponse {
  final String query;
  final String filter;
  final int total;
  final int limit;
  final int offset;
  final bool hasMore;
  final bool isSecretCodeMatch;
  final List<SearchChatItem> lockedChats;
  final List<SearchChatItem> chats;
  final List<SearchContactItem> contacts;
  final List<SearchMessageItem> messages;

  const GlobalSearchResponse({
    this.query = '',
    this.filter = 'all',
    this.total = 0,
    this.limit = 20,
    this.offset = 0,
    this.hasMore = false,
    this.isSecretCodeMatch = false,
    this.lockedChats = const [],
    this.chats = const [],
    this.contacts = const [],
    this.messages = const [],
  });

  factory GlobalSearchResponse.fromJson(Map<String, dynamic> json) {
    return GlobalSearchResponse(
      query: json['query']?.toString() ?? '',
      filter: json['filter']?.toString() ?? 'all',
      total: (json['total'] is num) ? (json['total'] as num).toInt() : 0,
      limit: (json['limit'] is num) ? (json['limit'] as num).toInt() : 20,
      offset: (json['offset'] is num) ? (json['offset'] as num).toInt() : 0,
      hasMore: json['hasMore'] == true || json['has_more'] == true,
      isSecretCodeMatch: json['isSecretCodeMatch'] == true || json['is_secret_code_match'] == true,
      lockedChats: ((json['lockedChats'] ?? json['locked_chats']) as List<dynamic>?)
              ?.map((e) => SearchChatItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      chats: (json['chats'] as List<dynamic>?)
              ?.map((e) => SearchChatItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      contacts: (json['contacts'] as List<dynamic>?)
              ?.map((e) => SearchContactItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      messages: (json['messages'] as List<dynamic>?)
              ?.map((e) => SearchMessageItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

class SearchChatItem {
  final String id;
  final bool isGroup;
  final String name;
  final String? phoneNumber;
  final String? pictureUrl;
  final int unreadCount;
  final String? lastMessageSnippet;
  final int? lastMessageTimestamp;
  final int? updatedAt;
  final bool isLocked;

  const SearchChatItem({
    required this.id,
    this.isGroup = false,
    required this.name,
    this.phoneNumber,
    this.pictureUrl,
    this.unreadCount = 0,
    this.lastMessageSnippet,
    this.lastMessageTimestamp,
    this.updatedAt,
    this.isLocked = false,
  });

  factory SearchChatItem.fromJson(Map<String, dynamic> json) {
    String? resolvedName = json['name']?.toString() ??
        json['contactName']?.toString() ??
        json['contact_name']?.toString() ??
        json['displayName']?.toString() ??
        json['display_name']?.toString() ??
        json['groupName']?.toString() ??
        json['group_name']?.toString();

    String? phone = json['phoneNumber']?.toString() ?? json['phone_number']?.toString();
    String? pic = json['pictureUrl']?.toString() ??
        json['picture_url']?.toString() ??
        json['profilePictureUrl']?.toString() ??
        json['profile_picture_url']?.toString() ??
        json['groupPictureUrl']?.toString() ??
        json['group_picture_url']?.toString();

    final recipient = json['recipient'];
    if (recipient is Map) {
      resolvedName ??= recipient['contactName']?.toString() ??
          recipient['contact_name']?.toString() ??
          recipient['name']?.toString() ??
          recipient['displayName']?.toString() ??
          recipient['username']?.toString();
      phone ??= recipient['phoneNumber']?.toString() ?? recipient['phone_number']?.toString();
      pic ??= recipient['profilePictureUrl']?.toString() ??
          recipient['profile_picture_url']?.toString() ??
          recipient['profile_picture']?.toString();
    }

    String? snippet = json['lastMessageSnippet']?.toString() ??
        json['last_message_snippet']?.toString() ??
        json['snippet']?.toString() ??
        json['message']?.toString();

    final lm = json['lastMessage'] ?? json['last_message'];
    if ((snippet == null || snippet.isEmpty) && lm != null) {
      if (lm is Map) {
        final content = lm['content'];
        if (content is Map) {
          snippet = content['text']?.toString() ??
              content['fileName']?.toString() ??
              content['caption']?.toString();
        } else if (content is String) {
          snippet = content;
        } else if (lm['text'] != null) {
          snippet = lm['text']?.toString();
        }
      } else if (lm is String) {
        snippet = lm;
      }
    }

    return SearchChatItem(
      id: (json['id'] ?? json['_id'])?.toString() ?? '',
      isGroup: json['isGroup'] == true || json['is_group'] == true,
      name: (resolvedName != null && resolvedName.isNotEmpty)
          ? resolvedName
          : (phone != null && phone.isNotEmpty ? phone : 'Chat'),
      phoneNumber: phone,
      pictureUrl: pic,
      unreadCount: (json['unreadCount'] ?? json['unread_count'] ?? 0) is num
          ? (json['unreadCount'] ?? json['unread_count'] ?? 0).toInt()
          : 0,
      lastMessageSnippet: snippet,
      lastMessageTimestamp: json['lastMessageTimestamp'] is num
          ? (json['lastMessageTimestamp'] as num).toInt()
          : (json['last_message_timestamp'] is num ? (json['last_message_timestamp'] as num).toInt() : null),
      updatedAt: json['updatedAt'] is num ? (json['updatedAt'] as num).toInt() : null,
      isLocked: json['isLocked'] == true || json['is_locked'] == true,
    );
  }
}

class SearchContactItem {
  final String? id;
  final String? contactName;
  final String? fullName;
  final String phoneNumber;
  final String? profilePictureUrl;
  final bool isRegistered;
  final String? conversationId;

  const SearchContactItem({
    this.id,
    this.contactName,
    this.fullName,
    required this.phoneNumber,
    this.profilePictureUrl,
    this.isRegistered = true,
    this.conversationId,
  });

  factory SearchContactItem.fromJson(Map<String, dynamic> json) {
    return SearchContactItem(
      id: json['id']?.toString(),
      contactName: json['contactName']?.toString() ?? json['contact_name']?.toString(),
      fullName: json['fullName']?.toString() ?? json['full_name']?.toString(),
      phoneNumber: json['phoneNumber']?.toString() ?? json['phone_number']?.toString() ?? '',
      profilePictureUrl: json['profilePictureUrl']?.toString() ?? json['profile_picture_url']?.toString(),
      isRegistered: json['isRegistered'] != false && json['is_registered'] != false,
      conversationId: json['conversationId']?.toString() ?? json['conversation_id']?.toString(),
    );
  }

  String get displayName =>
      (contactName?.isNotEmpty == true ? contactName : fullName)?.isNotEmpty == true
          ? (contactName?.isNotEmpty == true ? contactName! : fullName!)
          : phoneNumber;
}

class SearchMessageItem {
  final String id;
  final String conversationId;
  final String conversationName;
  final String? conversationPictureUrl;
  final String conversationType;
  final bool isGroup;
  final String senderId;
  final String? senderName;
  final String messageType;
  final String contentText;
  final String? mediaUrl;
  final String? fileName;
  final String? fileSize;
  final String? matchSnippet;
  final List<String> extractedUrls;
  final int createdAt;

  const SearchMessageItem({
    required this.id,
    required this.conversationId,
    required this.conversationName,
    this.conversationPictureUrl,
    this.conversationType = 'direct',
    this.isGroup = false,
    required this.senderId,
    this.senderName,
    this.messageType = 'text',
    required this.contentText,
    this.mediaUrl,
    this.fileName,
    this.fileSize,
    this.matchSnippet,
    this.extractedUrls = const [],
    this.createdAt = 0,
  });

  factory SearchMessageItem.fromJson(Map<String, dynamic> json) {
    String text = '';
    String? mediaUrl;
    String? fileName;
    String? fileSize;

    final content = json['content'];
    if (content is Map) {
      text = content['text']?.toString() ?? '';
      mediaUrl = (content['fileKey'] ?? content['file_key'] ?? content['url'])?.toString();
      fileName = (content['fileName'] ?? content['file_name'] ?? content['name'])?.toString();
      fileSize = (content['fileSize'] ?? content['file_size'] ?? content['size'])?.toString();
    } else if (content is String) {
      text = content;
    }

    if (json['matchSnippet'] != null || json['match_snippet'] != null) {
      final snippet = (json['matchSnippet'] ?? json['match_snippet'])?.toString() ?? '';
      if (snippet.isNotEmpty && text.isEmpty) {
        text = snippet;
      }
    }

    return SearchMessageItem(
      id: (json['id'] ?? json['_id'])?.toString() ?? '',
      conversationId: (json['conversationId'] ?? json['conversation_id'])?.toString() ?? '',
      conversationName: (json['conversationName'] ?? json['conversation_name'] ?? 'Chat').toString(),
      conversationPictureUrl: json['conversationPictureUrl']?.toString() ?? json['conversation_picture_url']?.toString(),
      conversationType: json['conversationType']?.toString() ?? json['conversation_type']?.toString() ?? 'direct',
      isGroup: json['isGroup'] == true || json['is_group'] == true,
      senderId: (json['senderId'] ?? json['sender_id'])?.toString() ?? '',
      senderName: json['senderName']?.toString() ?? json['sender_name']?.toString(),
      messageType: (json['type'] ?? json['message_type'] ?? 'text').toString().toLowerCase(),
      contentText: text,
      mediaUrl: mediaUrl,
      fileName: fileName,
      fileSize: fileSize,
      matchSnippet: json['matchSnippet']?.toString() ?? json['match_snippet']?.toString(),
      extractedUrls: (json['extractedUrls'] ?? json['extracted_urls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      createdAt: json['createdAt'] is num
          ? (json['createdAt'] as num).toInt()
          : (json['created_at'] is num ? (json['created_at'] as num).toInt() : 0),
    );
  }
}
