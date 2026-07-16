import 'package:schat/features/profile_screen/src/domain/models/user_model.dart';

/// Response model for `GET /api/v1/users/lookup?phone_number={phone_number}`.
///
/// - [exists] is `true` when the phone number belongs to a registered user.
/// - [user] carries the full profile when [exists] is `true`, otherwise `null`.
class PhoneLookupResponse {
  final bool exists;
  final UserModel? user;

  const PhoneLookupResponse({
    required this.exists,
    this.user,
  });

  factory PhoneLookupResponse.fromJson(Map<String, dynamic> json) {
    final exists = json['exists'] as bool? ?? false;
    final userJson = json['user'];
    final user = (exists && userJson != null)
        ? UserModel.fromJson(Map<String, dynamic>.from(userJson as Map))
        : null;
    return PhoneLookupResponse(exists: exists, user: user);
  }

  @override
  String toString() =>
      'PhoneLookupResponse(exists: $exists, user: ${user?.id})';
}
