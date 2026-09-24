class ScreenPermissionModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String receiverId;
  final String permissionType; // 'screenshot' or 'screen_record'
  final int? allowedCount;
  final int? durationSeconds;
  final int? remainingCount;
  final String status; // 'pending', 'accepted', 'rejected', 'expired', 'completed'
  final String? senderName;
  final String? senderAvatar;
  final String? receiverName;
  final String? receiverAvatar;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? expiresAt;

  const ScreenPermissionModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.receiverId,
    required this.permissionType,
    this.allowedCount,
    this.durationSeconds,
    this.remainingCount,
    required this.status,
    this.senderName,
    this.senderAvatar,
    this.receiverName,
    this.receiverAvatar,
    this.createdAt,
    this.updatedAt,
    this.expiresAt,
  });

  bool get isScreenshot => permissionType == 'screenshot';
  bool get isScreenRecord => permissionType == 'screen_record';
  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';
  bool get isCompleted => status == 'completed';

  factory ScreenPermissionModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      return DateTime.tryParse(val.toString());
    }

    return ScreenPermissionModel(
      id: json['id']?.toString() ?? '',
      conversationId: (json['conversationId'] ?? json['conversation_id'])?.toString() ?? '',
      senderId: (json['senderId'] ?? json['sender_id'])?.toString() ?? '',
      receiverId: (json['receiverId'] ?? json['receiver_id'])?.toString() ?? '',
      permissionType: (json['permissionType'] ?? json['permission_type'])?.toString() ?? 'screenshot',
      allowedCount: json['allowedCount'] as int? ?? json['allowed_count'] as int?,
      durationSeconds: json['durationSeconds'] as int? ?? json['duration_seconds'] as int?,
      remainingCount: json['remainingCount'] as int? ?? json['remaining_count'] as int?,
      status: json['status']?.toString() ?? 'pending',
      senderName: (json['senderName'] ?? json['sender_name'])?.toString(),
      senderAvatar: (json['senderAvatar'] ?? json['sender_avatar'])?.toString(),
      receiverName: (json['receiverName'] ?? json['receiver_name'])?.toString(),
      receiverAvatar: (json['receiverAvatar'] ?? json['receiver_avatar'])?.toString(),
      createdAt: parseDate(json['createdAt'] ?? json['created_at']),
      updatedAt: parseDate(json['updatedAt'] ?? json['updated_at']),
      expiresAt: parseDate(json['expiresAt'] ?? json['expires_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'receiverId': receiverId,
      'permissionType': permissionType,
      'allowedCount': allowedCount,
      'durationSeconds': durationSeconds,
      'remainingCount': remainingCount,
      'status': status,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'receiverName': receiverName,
      'receiverAvatar': receiverAvatar,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }

  ScreenPermissionModel copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? receiverId,
    String? permissionType,
    int? allowedCount,
    int? durationSeconds,
    int? remainingCount,
    String? status,
    String? senderName,
    String? senderAvatar,
    String? receiverName,
    String? receiverAvatar,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? expiresAt,
  }) {
    return ScreenPermissionModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      permissionType: permissionType ?? this.permissionType,
      allowedCount: allowedCount ?? this.allowedCount,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      remainingCount: remainingCount ?? this.remainingCount,
      status: status ?? this.status,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      receiverName: receiverName ?? this.receiverName,
      receiverAvatar: receiverAvatar ?? this.receiverAvatar,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}
