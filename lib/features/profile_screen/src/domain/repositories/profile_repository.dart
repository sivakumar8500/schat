import 'dart:io';

abstract class ProfileRepository {
  Future<bool> updateProfile(String username, File? image);
}
