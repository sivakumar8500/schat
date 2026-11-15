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
  final String? shareId;
  final int? permissionVersion;
  final FilePermissions permissions;
  final FilePermissions? grantedPermissions;

  MediaPermissionsModel({
    required this.fileId,
    required this.userId,
    required this.isOwner,
    this.shareId,
    this.permissionVersion,
    required this.permissions,
    this.grantedPermissions,
  });

  factory MediaPermissionsModel.fromJson(Map<String, dynamic> json) {
    return MediaPermissionsModel(
      fileId: (json['file_id'] ?? json['fileId'] ?? '').toString(),
      userId: (json['user_id'] ?? json['userId'] ?? '').toString(),
      isOwner: json['is_owner'] ?? json['isOwner'] ?? false,
      shareId: json['share_id']?.toString() ?? json['shareId']?.toString(),
      permissionVersion: json['permission_version'] != null
          ? int.tryParse(json['permission_version'].toString())
          : (json['permissionVersion'] != null ? int.tryParse(json['permissionVersion'].toString()) : null),
      permissions: json['permissions'] != null && json['permissions'] is Map<String, dynamic>
          ? FilePermissions.fromJson(json['permissions'] as Map<String, dynamic>)
          : FilePermissions(),
      grantedPermissions: json['granted_permissions'] != null && json['granted_permissions'] is Map<String, dynamic>
          ? FilePermissions.fromJson(json['granted_permissions'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'file_id': fileId,
        'user_id': userId,
        'is_owner': isOwner,
        'share_id': shareId,
        'permission_version': permissionVersion,
        'permissions': permissions.toJson(),
      };
}
