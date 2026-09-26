class ScheduledMessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String messageType;
  final String? parentMessageId;
  final String text;
  final String? fileKey;
  final String? thumbnail;
  final String? fileName;
  final int fileSize;
  final String? mimeType;
  final DateTime scheduledAt;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic> rawContent;

  ScheduledMessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.messageType,
    this.parentMessageId,
    required this.text,
    this.fileKey,
    this.thumbnail,
    this.fileName,
    this.fileSize = 0,
    this.mimeType,
    required this.scheduledAt,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.rawContent = const {},
  });

  factory ScheduledMessageModel.fromJson(Map<String, dynamic> json) {
    final content = (json['content'] is Map<String, dynamic>
            ? json['content'] as Map<String, dynamic>
            : null) ??
        (json['content_meta'] is Map<String, dynamic>
            ? json['content_meta'] as Map<String, dynamic>
            : null) ??
        (json['content'] is Map
            ? Map<String, dynamic>.from(json['content'] as Map)
            : null) ??
        {};

    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is DateTime) return val.toLocal();
      if (val is num) {
        final millis = val > 10000000000 ? val.toInt() : (val * 1000).toInt();
        return DateTime.fromMillisecondsSinceEpoch(
          millis,
          isUtc: true,
        ).toLocal();
      } else if (val is String) {
        final numVal = num.tryParse(val);
        if (numVal != null) {
          final millis = numVal > 10000000000 ? numVal.toInt() : (numVal * 1000).toInt();
          return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true).toLocal();
        }
        return DateTime.tryParse(val)?.toLocal() ?? DateTime.now();
      }
      return DateTime.now();
    }

    int parseSize(dynamic val) {
      if (val is int) return val;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    return ScheduledMessageModel(
      id: (json['id'] ??
              json['_id'] ??
              json['scheduled_message_id'] ??
              json['scheduledMessageId'] ??
              '')
          .toString(),
      conversationId: (json['conversationId'] ??
              json['conversation_id'] ??
              json['chat_id'] ??
              json['chatId'] ??
              json['groupId'] ??
              json['group_id'] ??
              json['recipientId'] ??
              json['recipient_id'] ??
              '')
          .toString(),
      senderId: (json['senderId'] ??
              json['sender_id'] ??
              json['user_id'] ??
              json['userId'] ??
              '')
          .toString(),
      messageType: (json['messageType'] ??
              json['message_type'] ??
              json['type'] ??
              'text')
          .toString(),
      parentMessageId: json['parentMessageId']?.toString() ??
          json['parent_message_id']?.toString(),
      text: content['text']?.toString() ??
          json['text']?.toString() ??
          json['message']?.toString() ??
          json['body']?.toString() ??
          '',
      fileKey: (content['fileKey'] ??
              content['file_key'] ??
              content['url'] ??
              content['mediaUrl'] ??
              content['media_url'] ??
              content['path'] ??
              content['filePath'] ??
              content['file_path'] ??
              json['fileKey'] ??
              json['file_key'] ??
              json['url'] ??
              json['path'])
          ?.toString(),
      thumbnail: (content['thumbnail'] ??
              content['thumb_url'] ??
              content['thumbUrl'] ??
              json['thumbnail'])
          ?.toString(),
      fileName: (content['fileName'] ??
              content['file_name'] ??
              content['name'] ??
              json['fileName'] ??
              json['file_name'] ??
              json['name'])
          ?.toString(),
      fileSize: parseSize(content['fileSize'] ??
          content['file_size'] ??
          content['size'] ??
          json['fileSize'] ??
          json['file_size'] ??
          json['size']),
      mimeType: (content['mimeType'] ??
              content['mime_type'] ??
              json['mimeType'] ??
              json['mime_type'])
          ?.toString(),
      scheduledAt: parseDate(json['scheduledAt'] ??
          json['scheduled_at'] ??
          json['scheduled_time'] ??
          json['scheduledTime'] ??
          json['send_at'] ??
          json['sendAt']),
      status: (json['status'] ?? 'pending').toString(),
      createdAt: json['createdAt'] != null || json['created_at'] != null
          ? parseDate(json['createdAt'] ?? json['created_at'])
          : null,
      updatedAt: json['updatedAt'] != null || json['updated_at'] != null
          ? parseDate(json['updatedAt'] ?? json['updated_at'])
          : null,
      rawContent: content.isNotEmpty
          ? content
          : (json['content'] is Map
              ? Map<String, dynamic>.from(json['content'] as Map)
              : {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'conversationId': conversationId,
        'senderId': senderId,
        'messageType': messageType,
        'parentMessageId': parentMessageId,
        'content': rawContent,
        'scheduledAt': scheduledAt.toUtc().toIso8601String(),
        'status': status,
        'createdAt': createdAt?.toUtc().toIso8601String(),
        'updatedAt': updatedAt?.toUtc().toIso8601String(),
      };
}
