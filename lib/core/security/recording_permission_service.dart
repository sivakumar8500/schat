import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:schat/features/chat_screen/src/domain/models/screen_permission_model.dart';
import 'package:schat/features/chat_screen/src/domain/repositories/chat_repository.dart';
import 'package:schat/injection.dart';

import 'package:schat/core/storage/storage_service.dart';

/// Phase 5: Service for managing authoritative server-side screen recording permissions,
/// UTC expiration calculations, and fail-closed privacy enforcement.
@lazySingleton
class RecordingPermissionService {
  ChatRepository get _chatRepo => getIt<ChatRepository>();

  final Map<String, DateTime> _grantExpirationMap = {};

  bool hasGrantExpiration(String permissionId) {
    if (_grantExpirationMap.containsKey(permissionId)) return true;
    try {
      if (getIt.isRegistered<StorageService>()) {
        final storage = getIt<StorageService>();
        return storage.getPermissionExpiration(permissionId) != null;
      }
    } catch (_) {}
    return false;
  }

  DateTime? getGrantExpiration(String permissionId) {
    if (_grantExpirationMap.containsKey(permissionId)) {
      return _grantExpirationMap[permissionId];
    }
    try {
      if (getIt.isRegistered<StorageService>()) {
        final storage = getIt<StorageService>();
        final exp = storage.getPermissionExpiration(permissionId);
        if (exp != null) {
          _grantExpirationMap[permissionId] = exp;
          return exp;
        }
      }
    } catch (_) {}
    return null;
  }

  void setGrantExpiration(String permissionId, DateTime expiresAt) {
    _grantExpirationMap[permissionId] = expiresAt;
    try {
      if (getIt.isRegistered<StorageService>()) {
        final storage = getIt<StorageService>();
        storage.savePermissionExpiration(permissionId, expiresAt);
      }
    } catch (_) {}
  }

  void clearGrantExpiration(String permissionId) {
    _grantExpirationMap.remove(permissionId);
    try {
      if (getIt.isRegistered<StorageService>()) {
        final storage = getIt<StorageService>();
        storage.clearPermissionExpiration(permissionId);
      }
    } catch (_) {}
  }

  /// Calculates authoritative remaining duration in seconds from the original UTC expiration timestamp.
  /// Never extends duration locally; countdown stops strictly at zero.
  int calculateRemainingSeconds(DateTime? expiresAt) {
    if (expiresAt == null) return 0;
    final nowUtc = DateTime.now().toUtc();
    final expUtc = expiresAt.toUtc();
    final diff = expUtc.difference(nowUtc).inSeconds;
    return diff > 0 ? diff : 0;
  }

  /// Authoritative check: returns true only if the grant is active, intended for screen record,
  /// matches the expected chat (if provided), and not expired or revoked.
  bool isGrantValid(ScreenPermissionModel? model, {String? expectedChatId}) {
    if (model == null) return false;
    if (expectedChatId != null && model.conversationId != expectedChatId) return false;
    if (!model.isScreenRecord) return false;
    if (model.isRevoked || model.isCompleted || model.isRejected) return false;
    if (!model.isAccepted) return false;

    // Check persistent expiration if available
    final persistentExp = getGrantExpiration(model.id);
    if (persistentExp != null) {
      return calculateRemainingSeconds(persistentExp) > 0;
    }

    if (model.expiresAt == null) return true;
    return calculateRemainingSeconds(model.expiresAt) > 0;
  }

  /// Convenience alias for isGrantValid.
  bool validatePermission(ScreenPermissionModel? model, {String? expectedChatId}) =>
      isGrantValid(model, expectedChatId: expectedChatId);

  /// Fetches the authenticated user's permission status from the server.
  /// Fails closed: on network failure or authorization error, returns null (no access).
  Future<ScreenPermissionModel?> getActivePermission(String conversationId) async {
    try {
      // First attempt the standardized Phase 4 endpoint
      final mePermission = await _chatRepo.getRecordingPermissionMe(conversationId);
      if (mePermission != null && isGrantValid(mePermission)) {
        return mePermission;
      }

      // Fallback to active screen permission endpoint
      final activeList = await _chatRepo.getActiveScreenPermissions(conversationId);
      for (final p in activeList) {
        if (p.isScreenRecord && isGrantValid(p)) {
          return p;
        }
      }
      return null;
    } catch (e) {
      debugPrint('RecordingPermissionService: Failed to fetch permission (failing closed): $e');
      return null;
    }
  }

  /// Requests a screen recording permission grant for the specified conversation.
  /// Request creation is idempotent.
  Future<ScreenPermissionModel?> requestPermission(
    String conversationId, {
    int durationSeconds = 30,
  }) async {
    try {
      return await _chatRepo.createRecordingPermission(
        conversationId,
        durationSeconds: durationSeconds,
      );
    } catch (e) {
      debugPrint('RecordingPermissionService: Error requesting permission: $e');
      return null;
    }
  }

  /// Explicitly revokes a grant. Fails closed.
  Future<bool> revokePermission(String conversationId, String permissionId) async {
    try {
      await _chatRepo.revokeRecordingPermission(conversationId, permissionId);
      return true;
    } catch (e) {
      debugPrint('RecordingPermissionService: Error revoking permission: $e');
      return false;
    }
  }

  /// Authorizes a recording session on the server before starting recording.
  /// Fails closed if the grant is expired, revoked, or non-existent.
  Future<Map<String, dynamic>?> authorizeRecordingSession(
    String conversationId, {
    String? permissionId,
  }) async {
    // 1. Try standardized Phase 4 endpoint
    try {
      final res = await _chatRepo.createRecordingSession(
        conversationId,
        permissionId: permissionId,
      );
      if (res.isNotEmpty) {
        return res;
      }
    } catch (e) {
      debugPrint('RecordingPermissionService: Standardized session endpoint unavailable ($e). Verifying active grant fallback...');
    }

    // 2. Backward-compatible fallback: verify active grant via getActivePermission
    try {
      final active = await getActivePermission(conversationId);
      if (active != null && isGrantValid(active, expectedChatId: conversationId)) {
        if (permissionId == null || active.id == permissionId) {
          return {
            'session_id': 'sess_${active.id}_${DateTime.now().millisecondsSinceEpoch}',
            'authorized': true,
            'permission_id': active.id,
            'remaining_seconds': active.computedRemainingSeconds,
          };
        }
      }
    } catch (e) {
      debugPrint('RecordingPermissionService: Fallback active grant verification failed: $e');
    }
    return null;
  }
}

/// Phase 5: Controller managing active, expired, and revoked states for a chat session.
/// Recalculates remaining time purely from original UTC expiration timestamp.
class RecordingPermissionController {
  final String conversationId;
  final RecordingPermissionService _service;
  final VoidCallback? onExpired;
  final ValueChanged<int>? onTick;

  ScreenPermissionModel? _permission;
  ScreenPermissionModel? get permission => _permission;

  int _remainingSeconds = 0;
  int get remainingSeconds => _remainingSeconds;

  bool _isActive = false;
  bool get isActive => _isActive;

  Timer? _tickerTimer;
  bool _isDisposed = false;

  RecordingPermissionController({
    required this.conversationId,
    RecordingPermissionService? service,
    this.onExpired,
    this.onTick,
  }) : _service = service ?? getIt<RecordingPermissionService>();

  /// Updates permission state and initializes remaining seconds from server timestamp.
  void setPermission(ScreenPermissionModel? model) {
    if (_isDisposed) return;
    _permission = model;

    if (model != null && _service.isGrantValid(model)) {
      _remainingSeconds = _service.calculateRemainingSeconds(model.expiresAt);
      _isActive = _remainingSeconds > 0;
      if (_isActive) {
        _startTicker();
      } else {
        _stopTicker();
      }
    } else {
      _remainingSeconds = 0;
      _isActive = false;
      _stopTicker();
    }
  }

  /// Recalculates remaining duration on app resume or chat reopen.
  void refreshRemainingTime() {
    if (_isDisposed || _permission == null) return;
    final exp = _permission!.expiresAt;
    if (exp != null) {
      _remainingSeconds = _service.calculateRemainingSeconds(exp);
      if (_remainingSeconds <= 0) {
        _isActive = false;
        _stopTicker();
        onExpired?.call();
      } else {
        _isActive = true;
      }
      onTick?.call(_remainingSeconds);
    }
  }

  void _startTicker() {
    _tickerTimer?.cancel();
    if (_permission?.expiresAt == null) return;

    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isDisposed) {
        timer.cancel();
        return;
      }

      final remaining = _service.calculateRemainingSeconds(_permission!.expiresAt);
      _remainingSeconds = remaining;
      onTick?.call(remaining);

      if (remaining <= 0) {
        timer.cancel();
        _tickerTimer = null;
        _isActive = false;
        onExpired?.call();
      }
    });
  }

  void _stopTicker() {
    _tickerTimer?.cancel();
    _tickerTimer = null;
  }

  void dispose() {
    _isDisposed = true;
    _stopTicker();
  }
}
