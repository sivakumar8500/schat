class ScheduledMessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String messageType;
  final String? parentMessageId;
  final String text;
  final String? fileKey;
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
        {};

    DateTime parseDate(dynamic val) {
      if (val is int) {
        return DateTime.fromMillisecondsSinceEpoch(
          val > 10000000000 ? val : val * 1000,
          isUtc: true,
        ).toLocal();
      } else if (val is String) {
        return DateTime.tryParse(val)?.toLocal() ?? DateTime.now();
      }
      return DateTime.now();
    }

    return ScheduledMessageModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      conversationId:
          (json['conversationId'] ?? json['conversation_id'] ?? '').toString(),
      senderId: (json['senderId'] ?? json['sender_id'] ?? '').toString(),
      messageType:
          (json['messageType'] ?? json['message_type'] ?? 'text').toString(),
      parentMessageId: json['parentMessageId']?.toString() ??
          json['parent_message_id']?.toString(),
      text: content['text']?.toString() ?? '',
      fileKey:
          content['fileKey']?.toString() ?? content['file_key']?.toString(),
      fileName:
          content['fileName']?.toString() ?? content['file_name']?.toString(),
      fileSize: (content['fileSize'] ?? content['file_size'] ?? 0) is int
          ? (content['fileSize'] ?? content['file_size'] ?? 0) as int
          : 0,
      mimeType:
          content['mimeType']?.toString() ?? content['mime_type']?.toString(),
      scheduledAt: parseDate(json['scheduledAt'] ?? json['scheduled_at']),
      status: (json['status'] ?? 'pending').toString(),
      createdAt: json['createdAt'] != null || json['created_at'] != null
          ? parseDate(json['createdAt'] ?? json['created_at'])
          : null,
      updatedAt: json['updatedAt'] != null || json['updated_at'] != null
          ? parseDate(json['updatedAt'] ?? json['updated_at'])
          : null,
      rawContent: content,
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
