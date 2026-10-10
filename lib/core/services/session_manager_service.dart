import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:schat/features/auth_screen/auth_screen.dart';
import 'package:schat/features/auth_screen/src/domain/repositories/auth_repository.dart';
import 'package:schat/injection.dart';
import 'package:schat/main.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_spaces.dart';
import 'package:schat/utils/common_notifications.dart';

@lazySingleton
class SessionManagerService {
  bool _isLoggingOut = false;
  bool _isProtectedSession = false;

  void setProtectedSession(bool isProtected) {
    _isProtectedSession = isProtected;
    debugPrint('SessionManagerService: setProtectedSession = $isProtected');
  }

  bool get isProtectedSession => _isProtectedSession;

  /// Handles real-time auto logout (e.g. when account is logged in on another device,
  /// token invalidated 401, or manual logout) and automatically routes to the login screen.
  Future<void> logoutAndRedirectToLogin({
    String reason = 'You have been logged out because your account was logged in on another device.',
    bool showNotification = true,
  }) async {
    if (_isLoggingOut) return;
    if (_isProtectedSession) {
      debugPrint('SessionManagerService: Ignored logout redirect because session is currently protected (e.g. resetting chat lock password).');
      return;
    }
    _isLoggingOut = true;

    try {
      debugPrint('SessionManagerService: Initiating global auto-logout (reason: $reason)');

      // 1. Wipe local session, active calls, sockets, and storage
      if (getIt.isRegistered<AuthRepository>()) {
        await getIt<AuthRepository>().logout();
      }

      // 2. Clear entire navigation stack and move directly to MobileEntryPage
      final navState = navigatorKey.currentState;
      if (navState != null) {
        navState.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MobileEntryPage()),
          (Route<dynamic> route) => false,
        );

        // 3. Show notification on login screen
        if (showNotification) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final currentCtx = navigatorKey.currentContext;
            if (currentCtx != null && currentCtx.mounted) {
              currentCtx.showErrorNotification(reason);
            }
          });
        }
      }
    } catch (e) {
      debugPrint('SessionManagerService: Error during auto-logout: $e');
    } finally {
      _isLoggingOut = false;
    }
  }

  /// Displays the "Already Logged In on Another Device" bottom sheet
  /// allowing the user to confirm kicking out other devices or cancel login.
  Future<bool> showDeviceConflictBottomSheet(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DeviceConflictBottomSheetContent(
        onConfirm: () => Navigator.of(ctx).pop(true),
        onCancel: () => Navigator.of(ctx).pop(false),
      ),
    );
    return result ?? false;
  }
}

class _DeviceConflictBottomSheetContent extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _DeviceConflictBottomSheetContent({
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.scaffoldBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.colors.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            CommonSpaces.h20,

            // Warning Icon with animated halo
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFEAB308).withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFEAB308).withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.phonelink_erase_rounded,
                  color: Color(0xFFEAB308),
                  size: 32,
                ),
              ),
            ),
            CommonSpaces.h16,

            // Title
            Text(
              'Already Logged In',
              style: context.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: context.colors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            CommonSpaces.h8,

            // Description
            Text(
              'This account is currently active on another device. Logging in here will automatically sign out all other devices to keep your messages and calls secure.',
              style: context.bodyMedium.copyWith(
                color: context.colors.textSecondary,
                fontSize: 14,
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
            CommonSpaces.h24,

            // Confirm Button (Log out other devices)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00873C),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Continue & Log Out Other Devices',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            CommonSpaces.h10,

            // Cancel Button
            SizedBox(
              width: double.infinity,
              height: 44,
              child: TextButton(
                onPressed: onCancel,
                style: TextButton.styleFrom(
                  foregroundColor: context.colors.textSecondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
