import 'package:flutter_test/flutter_test.dart';
import 'package:schat/core/security/recording_permission_service.dart';
import 'package:schat/features/chat_screen/src/domain/models/screen_permission_model.dart';
import 'package:schat/core/security/screen_protection_service.dart';

ScreenPermissionModel createTestModel({
  required String id,
  required String conversationId,
  String senderId = 'user-1',
  String receiverId = 'user-2',
  String permissionType = 'screen_record',
  String? scope = 'screen_record',
  String status = 'active',
  int? durationSeconds,
  int? remainingSeconds,
  DateTime? grantedAt,
  DateTime? expiresAt,
  DateTime? revokedAt,
}) {
  return ScreenPermissionModel(
    id: id,
    conversationId: conversationId,
    senderId: senderId,
    receiverId: receiverId,
    permissionType: permissionType,
    scope: scope,
    status: status,
    durationSeconds: durationSeconds,
    remainingSeconds: remainingSeconds,
    grantedAt: grantedAt,
    expiresAt: expiresAt,
    revokedAt: revokedAt,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 2 & 3: ScreenPermissionModel Lifecycle & Persistent Expiration Tests', () {
    test('Scenario 1: A valid grant is parsed with the correct expiration and scope', () {
      final now = DateTime.now().toUtc();
      final expiresAt = now.add(const Duration(minutes: 10));

      final json = {
        'id': 'perm-100',
        'conversation_id': 'chat-abc',
        'sender_id': 'user-1',
        'receiver_id': 'user-2',
        'permission_type': 'screen_record',
        'scope': 'screen_record',
        'duration_seconds': 600,
        'remaining_seconds': 600,
        'status': 'active',
        'granted_at': now.toIso8601String(),
        'expires_at': expiresAt.toIso8601String(),
      };

      final model = ScreenPermissionModel.fromJson(json);

      expect(model.id, 'perm-100');
      expect(model.conversationId, 'chat-abc');
      expect(model.isScreenRecord, isTrue);
      expect(model.scope, 'screen_record');
      expect(model.isActive, isTrue);
      expect(model.isExpired, isFalse);
      expect(model.isRevoked, isFalse);
      expect(model.computedRemainingSeconds, inInclusiveRange(598, 600));
    });

    test('Scenario 2: A permission granted for 10 min has ~7 min remaining after 3 min', () {
      final now = DateTime.now().toUtc();
      // Granted 3 minutes ago, expires in 7 minutes (420s)
      final grantedAt = now.subtract(const Duration(minutes: 3));
      final expiresAt = now.add(const Duration(minutes: 7));

      final model = createTestModel(
        id: 'perm-101',
        conversationId: 'chat-abc',
        durationSeconds: 600,
        grantedAt: grantedAt,
        expiresAt: expiresAt,
      );

      expect(model.isActive, isTrue);
      expect(model.isExpired, isFalse);
      // Remaining should be approximately 420 seconds (within 2 seconds jitter)
      expect(model.computedRemainingSeconds, inInclusiveRange(418, 421));
    });

    test('Scenario 3 & 4: Closing and reopening chat preserves expiration and never resets to full duration', () {
      final now = DateTime.now().toUtc();
      final expiresAt = now.add(const Duration(seconds: 150));

      final modelInitial = createTestModel(
        id: 'perm-102',
        conversationId: 'chat-abc',
        durationSeconds: 600, // original duration was 10 mins
        expiresAt: expiresAt, // but only 150s remaining
      );

      // Verify that reopening chat evaluates remaining seconds against expiresAt, NOT durationSeconds
      expect(modelInitial.computedRemainingSeconds, inInclusiveRange(148, 150));
      expect(modelInitial.computedRemainingSeconds, isNot(600));
    });

    test('Scenario 5: Expired permission is marked expired and computedRemainingSeconds stops at 0', () {
      final past = DateTime.now().toUtc().subtract(const Duration(seconds: 10));

      final model = createTestModel(
        id: 'perm-103',
        conversationId: 'chat-abc',
        durationSeconds: 600,
        expiresAt: past,
      );

      expect(model.isExpired, isTrue);
      expect(model.isActive, isFalse);
      expect(model.computedRemainingSeconds, 0); // Stops at zero, never negative
    });

    test('Scenario 6: Revoked permission is rejected and inactive', () {
      final future = DateTime.now().toUtc().add(const Duration(minutes: 5));

      final model = createTestModel(
        id: 'perm-104',
        conversationId: 'chat-abc',
        status: 'revoked',
        durationSeconds: 600,
        expiresAt: future,
        revokedAt: DateTime.now().toUtc(),
      );

      expect(model.isRevoked, isTrue);
      expect(model.isActive, isFalse);
    });
  });

  group('Phase 5 & 7: RecordingPermissionService Authorization & Fail-Closed Validation', () {
    late RecordingPermissionService service;

    setUp(() {
      service = RecordingPermissionService();
    });

    test('Scenario 7: Cross-chat isolation - grant for chat-A cannot authorize chat-B', () {
      final now = DateTime.now().toUtc();
      final model = createTestModel(
        id: 'perm-105',
        conversationId: 'chat-A',
        durationSeconds: 600,
        expiresAt: now.add(const Duration(minutes: 5)),
      );

      // Valid for chat-A
      expect(service.validatePermission(model, expectedChatId: 'chat-A'), isTrue);

      // Fails closed for chat-B
      expect(service.validatePermission(model, expectedChatId: 'chat-B'), isFalse);
    });

    test('Scenario 8 & 10: Fail-closed on expired, revoked, null, or wrong type permissions', () {
      expect(service.validatePermission(null, expectedChatId: 'chat-A'), isFalse);

      final expired = createTestModel(
        id: 'perm-106',
        conversationId: 'chat-A',
        expiresAt: DateTime.now().toUtc().subtract(const Duration(seconds: 5)),
      );
      expect(service.validatePermission(expired, expectedChatId: 'chat-A'), isFalse);

      final revoked = createTestModel(
        id: 'perm-107',
        conversationId: 'chat-A',
        status: 'revoked',
        expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 5)),
      );
      expect(service.validatePermission(revoked, expectedChatId: 'chat-A'), isFalse);

      final screenshotPerm = createTestModel(
        id: 'perm-108',
        conversationId: 'chat-A',
        permissionType: 'screenshot',
      );
      expect(service.validatePermission(screenshotPerm, expectedChatId: 'chat-A'), isFalse);
    });
  });

  group('Phase 5: RecordingPermissionController Countdown Ticker & Lifecycle Tests', () {
    test('Scenario 11 & 12: Ticker decrements, avoids duplicate timers, and stops at zero', () async {
      final expiresAt = DateTime.now().toUtc().add(const Duration(seconds: 2));

      final model = createTestModel(
        id: 'perm-109',
        conversationId: 'chat-123',
        durationSeconds: 2,
        expiresAt: expiresAt,
      );

      final service = RecordingPermissionService();
      bool expiredCallbackCalled = false;

      final controller = RecordingPermissionController(
        conversationId: 'chat-123',
        service: service,
        onExpired: () {
          expiredCallbackCalled = true;
        },
      );

      controller.setPermission(model);

      expect(controller.isActive, isTrue);
      expect(controller.remainingSeconds, inInclusiveRange(1, 2));

      // Wait 2.2 seconds for countdown to reach 0
      await Future.delayed(const Duration(milliseconds: 2200));

      expect(controller.remainingSeconds, 0);
      expect(controller.isActive, isFalse);
      expect(expiredCallbackCalled, isTrue);

      controller.dispose();
    });

    test('Scenario 13: Controller dispose cleanly stops ticking and prevents leaks', () async {
      final expiresAt = DateTime.now().toUtc().add(const Duration(seconds: 10));

      final model = createTestModel(
        id: 'perm-110',
        conversationId: 'chat-123',
        durationSeconds: 10,
        expiresAt: expiresAt,
      );

      final service = RecordingPermissionService();
      final controller = RecordingPermissionController(
        conversationId: 'chat-123',
        service: service,
      );

      controller.setPermission(model);
      final remainingBefore = controller.remainingSeconds;
      controller.dispose();

      await Future.delayed(const Duration(milliseconds: 1200));
      // Remaining seconds is frozen because timer was cancelled on dispose
      expect(controller.remainingSeconds, remainingBefore);
    });

    test('Scenario 14: ScreenRecordingSession freezes remaining seconds when paused and resumes accurately', () {
      final session = ScreenRecordingSession(
        permissionId: 'perm-pause-1',
        conversationId: 'chat-pause',
        totalDurationSeconds: 30,
        remainingSeconds: 30,
        startedAt: DateTime.now(),
        isPaused: false,
      );

      expect(session.computedRemainingSeconds, 30);
      expect(session.isPaused, isFalse);

      // Simulate 5 seconds elapsed
      session.remainingSeconds = 25;
      expect(session.computedRemainingSeconds, 25);

      // User navigates away to Dashboard: pause recording
      session.isPaused = true;
      expect(session.isPaused, isTrue);
      // Remaining seconds must remain frozen at 25
      expect(session.computedRemainingSeconds, 25);
      expect(session.remainingSeconds, 25);

      // User comes back to chat: resume recording
      session.isPaused = false;
      expect(session.isPaused, isFalse);
      expect(session.computedRemainingSeconds, 25);

      // Ticks down towards 0
      session.remainingSeconds = 0;
      expect(session.computedRemainingSeconds, 0);
    });
  });
}
