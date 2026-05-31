import 'dart:io';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:schat/features/profile_screen/src/domain/repositories/profile_repository.dart';

@LazySingleton(as: ProfileRepository)
class ProfileRepositoryImpl implements ProfileRepository {
  // ignore: unused_field
  final Dio _dio;

  ProfileRepositoryImpl(this._dio);

  @override
  Future<bool> updateProfile(String username, File? image) async {
    try {
      /*

      FormData formData = FormData.fromMap({
        'username': username,
        if (image != null)
          'profile_pic': await MultipartFile.fromFile(image.path, filename: 'profile.jpg'),
      });
      final response = await _dio.post('/user/profile', data: formData);
      return response.statusCode == 200;
      */

      // Simulating network request for now
      await Future.delayed(const Duration(seconds: 2));
      return true;
    } catch (e) {
      return false;
    }
  }
}
