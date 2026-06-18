import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:schat/core/network/api_result.dart';
import 'package:schat/core/network/api_service.dart';
import 'package:schat/core/storage/storage_service.dart';
import 'package:schat/features/profile_screen/src/data/repositories/profile_repository_impl.dart';
import 'package:schat/features/profile_screen/src/domain/models/update_profile_request.dart';
import 'package:schat/features/profile_screen/src/domain/models/user_model.dart';

class MockApiService extends Mock implements ApiService {}
class MockStorageService extends Mock implements StorageService {}

void main() {
  late ProfileRepositoryImpl repository;
  late MockApiService mockApiService;
  late MockStorageService mockStorageService;

  setUp(() {
    mockApiService = MockApiService();
    mockStorageService = MockStorageService();
    repository = ProfileRepositoryImpl(mockApiService, mockStorageService);
    
    when(() => mockStorageService.saveUserId(any())).thenAnswer((_) async {});
  });

  group('ProfileRepositoryImpl', () {
    test('updateProfile returns success', () async {
      final request = UpdateProfileRequest(username: 'testuser');
      final now = DateTime.now().toIso8601String();
      final mockUser = UserModel(
        id: '1',
        phoneNumber: '1234567890',
        username: 'testuser',
        isActive: true,
        isOnline: true,
        isSubscribed: true,
        createdAt: now,
        updatedAt: now,
      );
      
      when(() => mockApiService.call<UserModel>(
            path: any(named: 'path'),
            method: any(named: 'method'),
            data: any(named: 'data'), 
            mapper: any(named: 'mapper')
          )).thenAnswer((_) async => Success(mockUser));

      final result = await repository.updateProfile(request);
      expect(result is Success, isTrue);
      verify(() => mockStorageService.saveUserId('1')).called(1);
    });
  });
}
