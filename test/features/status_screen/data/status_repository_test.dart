import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:schat/core/network/api_result.dart';
import 'package:schat/core/network/api_service.dart';
import 'package:schat/features/status_screen/src/data/repositories/status_repository_impl.dart';
import 'package:schat/utils/common_endpoints.dart';

class MockApiService extends Mock implements ApiService {}

void main() {
  late StatusRepositoryImpl repository;
  late MockApiService mockApiService;

  setUp(() {
    mockApiService = MockApiService();
    repository = StatusRepositoryImpl(mockApiService);
  });

  group('StatusRepositoryImpl Video Status Tests', () {
    test('createStatus text status calls createStatus endpoint', () async {
      when(() => mockApiService.post(
        CommonEndpoints.createStatus,
        data: any(named: 'data'),
      )).thenAnswer((_) async => ApiResult.success({'id': 'status-123'}));

      await repository.createStatus(
        statusType: 'text',
        textContent: 'Hello Status',
        textColor: '#FFFFFF',
      );

      verify(() => mockApiService.post(
        CommonEndpoints.createStatus,
        data: any(
          named: 'data',
          that: predicate<Map<String, dynamic>>((map) {
            return map['status_type'] == 'text' &&
                map['textContent'] == 'Hello Status';
          }),
        ),
      )).called(1);
    });

    test('createStatus video status with direct upload fallback when requestUpload returns fallback endpoint', () async {
      // 1. requestUpload returns fallback /api/v1/media/upload
      when(() => mockApiService.call<Map<String, dynamic>>(
        path: CommonEndpoints.requestUpload,
        method: 'POST',
        data: any(named: 'data'),
        options: any(named: 'options'),
        mapper: any(named: 'mapper'),
      )).thenAnswer((_) async => ApiResult.success({
        'media_id': '11111111-1111-1111-1111-111111111111',
        'upload_url': '/api/v1/media/upload',
      }));

      // 2. Direct upload succeeds
      when(() => mockApiService.call<Map<String, dynamic>>(
        path: CommonEndpoints.directUpload,
        method: 'POST',
        data: any(named: 'data'),
        options: any(named: 'options'),
        mapper: any(named: 'mapper'),
      )).thenAnswer((_) async => ApiResult.success({
        'id': '22222222-2222-2222-2222-222222222222',
        'status': 'COMPLETED',
      }));

      // 3. createStatus endpoint succeeds
      when(() => mockApiService.post(
        CommonEndpoints.createStatus,
        data: any(named: 'data'),
      )).thenAnswer((_) async => ApiResult.success({'id': 'status-vid-1'}));

      final dummyBytes = Uint8List.fromList([1, 2, 3, 4, 5]);

      await repository.createStatus(
        statusType: 'video',
        fileName: 'test_video.mp4',
        fileBytes: dummyBytes,
        textContent: 'Cool clip',
      );

      verify(() => mockApiService.call<Map<String, dynamic>>(
        path: CommonEndpoints.directUpload,
        method: 'POST',
        data: any(named: 'data'),
        options: any(named: 'options'),
        mapper: any(named: 'mapper'),
      )).called(1);

      verify(() => mockApiService.post(
        CommonEndpoints.createStatus,
        data: any(
          named: 'data',
          that: predicate<Map<String, dynamic>>((map) {
            return map['status_type'] == 'video' &&
                map['media_file_id'] == '22222222-2222-2222-2222-222222222222';
          }),
        ),
      )).called(1);
    });

    test('createStatus video status directly falls back to directUpload if requestUpload fails', () async {
      // 1. requestUpload fails
      when(() => mockApiService.call<Map<String, dynamic>>(
        path: CommonEndpoints.requestUpload,
        method: 'POST',
        data: any(named: 'data'),
        options: any(named: 'options'),
        mapper: any(named: 'mapper'),
      )).thenAnswer((_) async => ApiResult.failure('S3 service down', statusCode: 500));

      // 2. Direct upload succeeds
      when(() => mockApiService.call<Map<String, dynamic>>(
        path: CommonEndpoints.directUpload,
        method: 'POST',
        data: any(named: 'data'),
        options: any(named: 'options'),
        mapper: any(named: 'mapper'),
      )).thenAnswer((_) async => ApiResult.success({
        'id': '33333333-3333-3333-3333-333333333333',
        'status': 'COMPLETED',
      }));

      // 3. createStatus endpoint succeeds
      when(() => mockApiService.post(
        CommonEndpoints.createStatus,
        data: any(named: 'data'),
      )).thenAnswer((_) async => ApiResult.success({'id': 'status-vid-2'}));

      final dummyBytes = Uint8List.fromList([1, 2, 3, 4, 5]);

      await repository.createStatus(
        statusType: 'video',
        fileName: 'my_story.mov',
        fileBytes: dummyBytes,
      );

      verify(() => mockApiService.call<Map<String, dynamic>>(
        path: CommonEndpoints.directUpload,
        method: 'POST',
        data: any(named: 'data'),
        options: any(named: 'options'),
        mapper: any(named: 'mapper'),
      )).called(1);

      verify(() => mockApiService.post(
        CommonEndpoints.createStatus,
        data: any(
          named: 'data',
          that: predicate<Map<String, dynamic>>((map) {
            return map['status_type'] == 'video' &&
                map['media_file_id'] == '33333333-3333-3333-3333-333333333333';
          }),
        ),
      )).called(1);
    });
  });
}
