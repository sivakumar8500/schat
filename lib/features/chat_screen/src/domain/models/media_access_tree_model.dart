import 'package:schat/features/chat_screen/src/domain/models/media_permissions_model.dart';

class AccessTreeUser {
  final String id;
  final String? email;
  final String? username;
  final String? name;

  AccessTreeUser({
    required this.id,
    this.email,
    this.username,
    this.name,
  });

  factory AccessTreeUser.fromJson(Map<String, dynamic> json) {
    return AccessTreeUser(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      email: json['email']?.toString(),
      username: json['username']?.toString(),
      name: json['name']?.toString() ?? json['username']?.toString(),
    );
  }

  String get displayName {
    if (name != null && name!.trim().isNotEmpty) return name!.trim();
    if (username != null && username!.trim().isNotEmpty) return username!.trim();
    if (email != null && email!.trim().isNotEmpty) return email!.trim();
    return 'User';
  }

  String get initials {
    final dn = displayName;
    if (dn.isNotEmpty) return dn[0].toUpperCase();
    return '?';
  }
}

class AccessTreeNode {
  final String grantId;
  final AccessTreeUser grantee;
  final AccessTreeUser granter;
  final FilePermissions permissions;
  final FilePermissions? ownerOverride;
  final FilePermissions effectivePermissions;
  final String status;
  final DateTime? createdAt;
  final List<AccessTreeNode> downstreamShares;

  AccessTreeNode({
    required this.grantId,
    required this.grantee,
    required this.granter,
    required this.permissions,
    this.ownerOverride,
    required this.effectivePermissions,
    required this.status,
    this.createdAt,
    this.downstreamShares = const [],
  });

  factory AccessTreeNode.fromJson(Map<String, dynamic> json) {
    DateTime? dt;
    if (json['created_at'] != null) {
      dt = DateTime.tryParse(json['created_at'].toString());
    }
    return AccessTreeNode(
      grantId: (json['grant_id'] ?? json['grantId'] ?? '').toString(),
      grantee: json['grantee'] != null && json['grantee'] is Map<String, dynamic>
          ? AccessTreeUser.fromJson(json['grantee'] as Map<String, dynamic>)
          : AccessTreeUser(id: (json['grantee_id'] ?? json['grantee'] ?? '').toString()),
      granter: json['granter'] != null && json['granter'] is Map<String, dynamic>
          ? AccessTreeUser.fromJson(json['granter'] as Map<String, dynamic>)
          : AccessTreeUser(id: (json['granter_id'] ?? json['granter'] ?? '').toString()),
      permissions: json['permissions'] != null && json['permissions'] is Map<String, dynamic>
          ? FilePermissions.fromJson(json['permissions'] as Map<String, dynamic>)
          : FilePermissions(),
      ownerOverride: json['owner_override'] != null && json['owner_override'] is Map<String, dynamic>
          ? FilePermissions.fromJson(json['owner_override'] as Map<String, dynamic>)
          : null,
      effectivePermissions: json['effective_permissions'] != null && json['effective_permissions'] is Map<String, dynamic>
          ? FilePermissions.fromJson(json['effective_permissions'] as Map<String, dynamic>)
          : (json['permissions'] != null && json['permissions'] is Map<String, dynamic>
              ? FilePermissions.fromJson(json['permissions'] as Map<String, dynamic>)
              : FilePermissions()),
      status: (json['status'] ?? 'active').toString(),
      createdAt: dt,
      downstreamShares: json['downstream_shares'] != null && json['downstream_shares'] is List
          ? (json['downstream_shares'] as List)
              .map((n) => AccessTreeNode.fromJson(n as Map<String, dynamic>))
              .toList()
          : [],
    );
  }
}

class MediaAccessTreeModel {
  final String fileId;
  final String uploaderId;
  final int totalGrants;
  final List<AccessTreeNode> accessTree;

  MediaAccessTreeModel({
    required this.fileId,
    required this.uploaderId,
    required this.totalGrants,
    required this.accessTree,
  });

  factory MediaAccessTreeModel.fromJson(Map<String, dynamic> json) {
    return MediaAccessTreeModel(
      fileId: (json['file_id'] ?? json['fileId'] ?? '').toString(),
      uploaderId: (json['uploader_id'] ?? json['uploaderId'] ?? '').toString(),
      totalGrants: int.tryParse((json['total_grants'] ?? json['totalGrants'] ?? 0).toString()) ?? 0,
      accessTree: json['access_tree'] != null && json['access_tree'] is List
          ? (json['access_tree'] as List)
              .map((n) => AccessTreeNode.fromJson(n as Map<String, dynamic>))
              .toList()
          : [],
    );
  }
}
