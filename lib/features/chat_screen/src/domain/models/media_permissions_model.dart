class FilePermissions {
  final bool canView;
  final bool canDownload;
  final bool canShare;

  FilePermissions({
    this.canView = true,
    this.canDownload = false,
    this.canShare = false,
  });

  factory FilePermissions.fromJson(Map<String, dynamic> json) {
    return FilePermissions(
      canView: json['can_view'] ?? json['canView'] ?? true,
      canDownload: json['can_download'] ?? json['canDownload'] ?? false,
      canShare: json['can_share'] ?? json['canShare'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'can_view': canView,
        'can_download': canDownload,
        'can_share': canShare,
      };
}

class MediaPermissionsModel {
  final String fileId;
  final String userId;
  final bool isOwner;
  final FilePermissions permissions;

  MediaPermissionsModel({
    required this.fileId,
    required this.userId,
    required this.isOwner,
    required this.permissions,
  });

  factory MediaPermissionsModel.fromJson(Map<String, dynamic> json) {
    return MediaPermissionsModel(
      fileId: (json['file_id'] ?? json['fileId'] ?? '').toString(),
      userId: (json['user_id'] ?? json['userId'] ?? '').toString(),
      isOwner: json['is_owner'] ?? json['isOwner'] ?? false,
      permissions: json['permissions'] != null && json['permissions'] is Map<String, dynamic>
          ? FilePermissions.fromJson(json['permissions'] as Map<String, dynamic>)
          : FilePermissions(),
    );
  }

  Map<String, dynamic> toJson() => {
        'file_id': fileId,
        'user_id': userId,
        'is_owner': isOwner,
        'permissions': permissions.toJson(),
      };
}
