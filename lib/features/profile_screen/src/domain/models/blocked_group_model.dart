class BlockedGroupModel {
  final String id;
  final String? groupName;
  final String? groupDescription;
  final String? groupPictureUrl;
  final String createdAt;

  const BlockedGroupModel({
    required this.id,
    this.groupName,
    this.groupDescription,
    this.groupPictureUrl,
    required this.createdAt,
  });

  factory BlockedGroupModel.fromJson(Map<String, dynamic> json) {
    return BlockedGroupModel(
      id: (json['id'] ?? json['_id'])?.toString() ?? '',
      groupName: json['groupName']?.toString(),
      groupDescription: json['groupDescription']?.toString(),
      groupPictureUrl: json['groupPictureUrl']?.toString(),
      createdAt: json['createdAt']?.toString() ?? json['created_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupName': groupName,
      'groupDescription': groupDescription,
      'groupPictureUrl': groupPictureUrl,
      'createdAt': createdAt,
    };
  }
}
