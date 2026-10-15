import 'package:schat/core/security/screen_protection_service.dart';
import 'package:schat/injection.dart';

class ScreenPermissionModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String receiverId;
  final String permissionType; // 'screenshot' or 'screen_record'
  final String? scope;
  final int? allowedCount;
  final int? durationSeconds;
  final int? remainingCount;
  final int? remainingSeconds;
  final String status; // 'pending', 'active', 'accepted', 'rejected', 'expired', 'revoked', 'completed'
  final String? senderName;
  final String? senderAvatar;
  final String? receiverName;
  final String? receiverAvatar;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? grantedAt;
  final DateTime? expiresAt;
  final DateTime? revokedAt;

  const ScreenPermissionModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.receiverId,
    required this.permissionType,
    this.scope,
    this.allowedCount,
    this.durationSeconds,
    this.remainingCount,
    this.remainingSeconds,
    required this.status,
    this.senderName,
    this.senderAvatar,
    this.receiverName,
    this.receiverAvatar,
    this.createdAt,
    this.updatedAt,
    this.grantedAt,
    this.expiresAt,
    this.revokedAt,
  });

  bool get isScreenshot => permissionType == 'screenshot';
  bool get isScreenRecord => permissionType == 'screen_record';
  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted' || status == 'active';
  bool get isRejected => status == 'rejected';
  bool get isRevoked => status == 'revoked';
  bool get isExpired {
    if (status == 'expired') return true;
    if (isScreenRecord) {
      try {
        if (getIt.isRegistered<ScreenProtectionService>()) {
          final session = getIt<ScreenProtectionService>().activeRecordingSession;
          if (session != null &&
              (session.permissionId == id ||
               session.permissionId.isEmpty ||
               session.conversationId == conversationId)) {
            return session.remainingSeconds <= 0;
          }
        }
      } catch (_) {}
      if (expiresAt != null && computedRemainingSeconds <= 0) return true;
    }
    return false;
  }
  bool get isCompleted => status == 'completed';
  bool get isActive => isAccepted && !isExpired && !isRevoked;

  int get computedRemainingSeconds {
    try {
      if (getIt.isRegistered<ScreenProtectionService>()) {
        final session = getIt<ScreenProtectionService>().activeRecordingSession;
        if (session != null &&
            (session.permissionId == id ||
             session.permissionId.isEmpty ||
             session.conversationId == conversationId)) {
          return session.computedRemainingSeconds;
        }
      }
    } catch (_) {}

    if (expiresAt != null) {
      final nowUtc = DateTime.now().toUtc();
      final expUtc = expiresAt!.toUtc();
      final diff = expUtc.difference(nowUtc).inSeconds;
      if (diff <= 0) return 0;
      // If expiresAt is set to the legacy 24h request validity window, cap to durationSeconds
      if (durationSeconds != null && durationSeconds! > 0 && diff > durationSeconds!) {
        return durationSeconds!;
      }
      return diff;
    }
    if (remainingSeconds != null) {
      return remainingSeconds! > 0 ? remainingSeconds! : 0;
    }
    return durationSeconds ?? 0;
  }

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
      scope: (json['scope'])?.toString(),
      allowedCount: json['allowedCount'] as int? ?? json['allowed_count'] as int?,
      durationSeconds: json['durationSeconds'] as int? ?? json['duration_seconds'] as int?,
      remainingCount: json['remainingCount'] as int? ?? json['remaining_count'] as int?,
      remainingSeconds: json['remainingSeconds'] as int? ?? json['remaining_seconds'] as int?,
      status: json['status']?.toString() ?? 'pending',
      senderName: (json['senderName'] ?? json['sender_name'])?.toString(),
      senderAvatar: (json['senderAvatar'] ?? json['sender_avatar'])?.toString(),
      receiverName: (json['receiverName'] ?? json['receiver_name'])?.toString(),
      receiverAvatar: (json['receiverAvatar'] ?? json['receiver_avatar'])?.toString(),
      createdAt: parseDate(json['createdAt'] ?? json['created_at']),
      updatedAt: parseDate(json['updatedAt'] ?? json['updated_at']),
      grantedAt: parseDate(json['grantedAt'] ?? json['granted_at']),
      expiresAt: parseDate(json['expiresAt'] ?? json['expires_at']),
      revokedAt: parseDate(json['revokedAt'] ?? json['revoked_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'receiverId': receiverId,
      'permissionType': permissionType,
      'scope': scope,
      'allowedCount': allowedCount,
      'durationSeconds': durationSeconds,
      'remainingCount': remainingCount,
      'remainingSeconds': remainingSeconds,
      'status': status,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'receiverName': receiverName,
      'receiverAvatar': receiverAvatar,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'grantedAt': grantedAt?.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'revokedAt': revokedAt?.toIso8601String(),
    };
  }

  ScreenPermissionModel copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? receiverId,
    String? permissionType,
    String? scope,
    int? allowedCount,
    int? durationSeconds,
    int? remainingCount,
    int? remainingSeconds,
    String? status,
    String? senderName,
    String? senderAvatar,
    String? receiverName,
    String? receiverAvatar,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? grantedAt,
    DateTime? expiresAt,
    DateTime? revokedAt,
  }) {
    return ScreenPermissionModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      permissionType: permissionType ?? this.permissionType,
      scope: scope ?? this.scope,
      allowedCount: allowedCount ?? this.allowedCount,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      remainingCount: remainingCount ?? this.remainingCount,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      status: status ?? this.status,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      receiverName: receiverName ?? this.receiverName,
      receiverAvatar: receiverAvatar ?? this.receiverAvatar,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      grantedAt: grantedAt ?? this.grantedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      revokedAt: revokedAt ?? this.revokedAt,
    );
  }
}
