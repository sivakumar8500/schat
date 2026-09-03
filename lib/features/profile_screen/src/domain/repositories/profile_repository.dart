import 'dart:typed_data';
import 'package:schat/core/network/api_result.dart';
import 'package:schat/features/profile_screen/src/domain/models/user_model.dart';
import 'package:schat/features/profile_screen/src/domain/models/update_profile_request.dart';
import 'package:schat/features/profile_screen/src/domain/models/blocked_group_model.dart';
import 'package:schat/features/profile_screen/src/domain/models/phone_lookup_response.dart';
import 'package:schat/features/profile_screen/src/data/models/add_emergency_contact_request.dart';
import 'package:schat/features/profile_screen/src/data/models/emergency_contact_response.dart';
abstract class ProfileRepository {
  Future<ApiResult<UserModel>> getProfile();
  Future<ApiResult<UserModel>> updateProfile(UpdateProfileRequest request);
  Future<ApiResult<UserModel>> getUserById(String userId);
  Future<String?> uploadProfilePicture({
    required String filePath,
    required String fileName,
    required String mimeType,
    required int fileSizeBytes,
    Uint8List? fileBytes,
  });

  Future<ApiResult<void>> blockUser(String userId);
  Future<ApiResult<void>> unblockUser(String userId);
  Future<ApiResult<List<UserModel>>> getBlockedUsers();
  Future<ApiResult<List<BlockedGroupModel>>> getBlockedGroups();

  /// Checks whether [phoneNumber] is registered and returns the user's profile
  /// if it is. Maps to `GET /api/v1/users/lookup?phone_number={phoneNumber}`.
  Future<ApiResult<PhoneLookupResponse>> lookupByPhoneNumber(String phoneNumber);

  Future<ApiResult<EmergencyContactResponse>> getAllEmergencyContacts();
  Future<ApiResult<PersonalContact>> addEmergencyContact(AddEmergencyContactRequest request);
  Future<ApiResult<PersonalContact>> updateEmergencyContact(String contactId, String contactName);
  Future<ApiResult<void>> deleteEmergencyContact(String contactId);
}

