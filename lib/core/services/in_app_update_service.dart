import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:injectable/injectable.dart';
import 'package:schat/core/services/widgets/app_update_dialog.dart';
import 'package:schat/main.dart';
import 'package:schat/utils/common_notifications.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import 'package:url_launcher/url_launcher.dart';

@lazySingleton
class InAppUpdateService {
  final ShorebirdUpdater _shorebirdUpdater = ShorebirdUpdater();
  bool _isChecking = false;
  DateTime? _lastCheckTime;

  /// Returns true if Shorebird Code Push engine is available on this device/build
  bool get isShorebirdAvailable => _shorebirdUpdater.isAvailable;

  /// Returns the current installed Shorebird patch number if available
  Future<int?> getCurrentPatchNumber() async {
    try {
      if (_shorebirdUpdater.isAvailable) {
        final patch = await _shorebirdUpdater.readCurrentPatch();
        return patch?.number;
      }
    } catch (e) {
      debugPrint('InAppUpdateService: Error reading patch number: $e');
    }
    return null;
  }

  /// Checks for available updates from Shorebird Code Push and Google Play Store.
  /// Automatically presents the update window/dialog when a new release is available.
  Future<void> checkForUpdate({
    BuildContext? context,
    bool isManualCheck = false,
  }) async {
    if (kIsWeb) return;

    // Avoid duplicate checks within 30 seconds unless manually triggered
    if (_isChecking) return;
    if (!isManualCheck && _lastCheckTime != null) {
      final diff = DateTime.now().difference(_lastCheckTime!);
      if (diff.inSeconds < 30) return;
    }

    _isChecking = true;
    _lastCheckTime = DateTime.now();

    final BuildContext? targetContext =
        context ?? navigatorKey.currentContext;

    try {
      // 1. Shorebird Code Push Check (Android & iOS)
      if (_shorebirdUpdater.isAvailable) {
        debugPrint('InAppUpdateService: Checking Shorebird Code Push for new release/patch...');
        final status = await _shorebirdUpdater.checkForUpdate();
        debugPrint('InAppUpdateService: Shorebird update status: $status');

        if (status == UpdateStatus.outdated) {
          debugPrint('InAppUpdateService: New Shorebird release available! Showing update window.');
          if (targetContext != null && targetContext.mounted) {
            await AppUpdateDialog.show(
              targetContext,
              updater: _shorebirdUpdater,
            );
          }
          return;
        } else if (status == UpdateStatus.restartRequired) {
          debugPrint('InAppUpdateService: Shorebird patch already downloaded, restart required.');
          if (targetContext != null && targetContext.mounted) {
            await AppUpdateDialog.show(
              targetContext,
              updater: _shorebirdUpdater,
            );
          }
          return;
        } else if (status == UpdateStatus.upToDate && isManualCheck) {
          if (targetContext != null && targetContext.mounted) {
            targetContext.showSuccessNotification('SChat is already up to date!');
          }
          return;
        }
      }

      // 2. Google Play Store In-App Update (Android native builds)
      if (defaultTargetPlatform == TargetPlatform.android) {
        debugPrint('InAppUpdateService: Checking Google Play Store for in-app updates...');
        try {
          final AppUpdateInfo updateInfo = await InAppUpdate.checkForUpdate();
          debugPrint('InAppUpdateService: Play Store updateAvailability = ${updateInfo.updateAvailability}, '
              'immediateAllowed = ${updateInfo.immediateUpdateAllowed}, '
              'flexibleAllowed = ${updateInfo.flexibleUpdateAllowed}, '
              'installStatus = ${updateInfo.installStatus}');

          if (updateInfo.installStatus == InstallStatus.downloaded) {
            if (targetContext != null && targetContext.mounted) {
              _showInstallDownloadedDialog(targetContext);
            } else {
              await InAppUpdate.completeFlexibleUpdate();
            }
            return;
          }

          if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
            if (updateInfo.flexibleUpdateAllowed) {
              final result = await InAppUpdate.startFlexibleUpdate();
              if (result == AppUpdateResult.success) {
                if (targetContext != null && targetContext.mounted) {
                  _showInstallDownloadedDialog(targetContext);
                } else {
                  await InAppUpdate.completeFlexibleUpdate();
                }
              }
            } else if (updateInfo.immediateUpdateAllowed) {
              await InAppUpdate.performImmediateUpdate();
            }
            return;
          }
        } catch (playError) {
          debugPrint('InAppUpdateService: Play Store update check note: $playError');
        }
      }

      // If manual check completed and no updates found
      if (isManualCheck && targetContext != null && targetContext.mounted) {
        targetContext.showSuccessNotification('SChat is up to date. You have the latest version.');
      }
    } catch (e) {
      debugPrint('InAppUpdateService: Update check error: $e');
      if (isManualCheck && targetContext != null && targetContext.mounted) {
        targetContext.showErrorNotification('Could not check for updates. Please try again later.');
      }
    } finally {
      _isChecking = false;
    }
  }

  /// Shows an in-app dialog prompting the user to restart and apply the downloaded update
  void _showInstallDownloadedDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFF1E293B),
        title: const Row(
          children: [
            Icon(Icons.system_update_rounded, color: Color(0xFF00A859), size: 26),
            SizedBox(width: 10),
            Text(
              'Update Ready',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: const Text(
          'An update for SChat has been downloaded. Restart the app now to finish installing the latest version.',
          style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Later', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await InAppUpdate.completeFlexibleUpdate();
              } catch (e) {
                debugPrint('InAppUpdateService: Error completing update: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00873C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Restart & Install', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  /// Opens the Play Store page directly as a fallback
  Future<void> openPlayStore() async {
    final uri = Uri.parse('market://details?id=com.sdpi.schat');
    final webUri = Uri.parse('https://play.google.com/store/apps/details?id=com.sdpi.schat');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('InAppUpdateService: Error opening Play Store: $e');
    }
  }
}
