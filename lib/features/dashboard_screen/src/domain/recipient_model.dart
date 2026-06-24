class RecipientModel {
  final String id;
  final String phoneNumber;
  final String? username;
  final String? firstName;
  final String? lastName;
  final String? profilePictureUrl;
  final String? about;
  final bool isActive;
  final bool isOnline;
  final String? lastSeen;
  final bool isSubscribed;
  final String? subscriptionType;
  final String createdAt;
  final String updatedAt;

  const RecipientModel({
    this.id = '',
    this.phoneNumber = '',
    this.username,
    this.firstName,
    this.lastName,
    this.profilePictureUrl,
    this.about,
    this.isActive = false,
    this.isOnline = false,
    this.lastSeen,
    this.isSubscribed = false,
    this.subscriptionType,
    this.createdAt = '',
    this.updatedAt = '',
  });

  factory RecipientModel.fromJson(Map<String, dynamic> json) {
    return RecipientModel(
      id: (json['id'] ?? json['_id'])?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString() ?? '',
      username: json['username']?.toString(),
      firstName: json['first_name']?.toString(),
      lastName: json['last_name']?.toString(),
      profilePictureUrl: json['profile_picture_url']?.toString(),
      about: json['about']?.toString(),
      isActive: json['is_active'] as bool? ?? false,
      isOnline: json['is_online'] as bool? ?? false,
      lastSeen: json['last_seen']?.toString(),
      isSubscribed: json['is_subscribed'] as bool? ?? false,
      subscriptionType: json['subscription_type']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'phone_number': phoneNumber,
        'username': username,
        'first_name': firstName,
        'last_name': lastName,
        'profile_picture_url': profilePictureUrl,
        'about': about,
        'is_active': isActive,
        'is_online': isOnline,
        'last_seen': lastSeen,
        'is_subscribed': isSubscribed,
        'subscription_type': subscriptionType,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  RecipientModel copyWith({
    String? id,
    String? phoneNumber,
    String? username,
    String? firstName,
    String? lastName,
    String? profilePictureUrl,
    String? about,
    bool? isActive,
    bool? isOnline,
    String? lastSeen,
    bool? isSubscribed,
    String? subscriptionType,
    String? createdAt,
    String? updatedAt,
  }) {
    return RecipientModel(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      username: username ?? this.username,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      about: about ?? this.about,
      isActive: isActive ?? this.isActive,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      isSubscribed: isSubscribed ?? this.isSubscribed,
      subscriptionType: subscriptionType ?? this.subscriptionType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
