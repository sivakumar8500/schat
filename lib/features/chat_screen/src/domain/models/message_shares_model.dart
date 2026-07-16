class ShareUser {
  final String id;
  final String username;
  final String firstName;
  final String lastName;
  final String? profilePictureUrl;

  const ShareUser({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    this.profilePictureUrl,
  });

  factory ShareUser.fromJson(Map<String, dynamic> json) {
    return ShareUser(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      firstName: (json['firstName'] ?? json['first_name'] ?? '').toString(),
      lastName: (json['lastName'] ?? json['last_name'] ?? '').toString(),
      profilePictureUrl: (json['profilePictureUrl'] ??
              json['profile_picture_url'] ??
              json['profilePicUrl'] ??
              json['avatar'])
          ?.toString(),
    );
  }

  String get displayName {
    final full = '${firstName.trim()} ${lastName.trim()}'.trim();
    return full.isNotEmpty ? full : username;
  }

  String get initials {
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '${firstName[0]}${lastName[0]}'.toUpperCase();
    }
    if (username.isNotEmpty) return username[0].toUpperCase();
    return '?';
  }
}

class MessageSharesModel {
  final int count;
  final List<ShareUser> users;

  const MessageSharesModel({
    required this.count,
    required this.users,
  });

  factory MessageSharesModel.fromJson(Map<String, dynamic> json) {
    final rawUsers = json['users'] ?? json['data'] ?? [];
    final List<ShareUser> parsedUsers = (rawUsers is List)
        ? rawUsers
            .map((u) => ShareUser.fromJson(Map<String, dynamic>.from(u as Map)))
            .toList()
        : [];
    return MessageSharesModel(
      count: int.tryParse(
              (json['count'] ?? json['total'] ?? parsedUsers.length).toString()) ??
          parsedUsers.length,
      users: parsedUsers,
    );
  }
}
