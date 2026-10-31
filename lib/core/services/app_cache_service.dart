import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';
import 'package:schat/core/security/secure_attachment_service.dart';

class AppCacheService {
  AppCacheService._();

  static const String _kAppInstalledInitializedKey = 'is_app_installed_initialized';

  /// Runs on app startup. When an app is uninstalled and reinstalled (or installed for the first time),
  /// SharedPreferences is empty. This automatically clears all residual cache, old encrypted files,
  /// temporary folders, and image caches by default.
  static Future<void> checkAndClearCacheOnFreshInstall() async {
    if (kIsWeb) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final isInitialized = prefs.getBool(_kAppInstalledInitializedKey) ?? false;

      if (!isInitialized) {
        debugPrint('[AppCacheService] Fresh installation or re-installation detected.');
        debugPrint('[AppCacheService] Clearing all residual cache and stale files by default...');

        // 1. Clear all file, disk, image, and external residual caches
        await clearAllAppCache(wipeExternalResidual: true);

        // 2. Clear stale Hive cache boxes if any persisted from system restore
        try {
          final boxNames = [
            'cached_messages',
            'opened_view_once_messages',
            'contacts_box',
            'muted_chats_box',
            'disappearing_timers_box',
            'blocked_users_box',
            'accepted_unknown_contacts',
            'user_uploaded_wallpapers',
            'chat_wallpapers',
            'chat_themes',
          ];
          for (final name in boxNames) {
            try {
              if (Hive.isBoxOpen(name)) {
                await Hive.box(name).clear();
              } else {
                await Hive.deleteBoxFromDisk(name);
              }
            } catch (_) {}
          }
        } catch (e) {
          debugPrint('[AppCacheService] Hive box cleanup error: $e');
        }

        // 3. Mark initialized so that subsequent normal restarts preserve active session cache
        await prefs.setBool(_kAppInstalledInitializedKey, true);
        debugPrint('[AppCacheService] Default cache purge on reinstall completed successfully.');
      }
    } catch (e) {
      debugPrint('[AppCacheService] checkAndClearCacheOnFreshInstall error: $e');
    }
  }

  /// Completely wipes application temporary cache, image cache, and attachment files.
  /// If [wipeExternalResidual] is true, also purges leftover legacy files in Android public folders.
  static Future<void> clearAllAppCache({bool wipeExternalResidual = true}) async {
    if (kIsWeb) return;

    // 1. Temporary directory contents
    try {
      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        final entities = tempDir.listSync(recursive: false);
        for (final entity in entities) {
          try {
            entity.deleteSync(recursive: true);
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('[AppCacheService] Error clearing temp directory: $e');
    }

    // 2. Android external cache directories
    if (Platform.isAndroid) {
      try {
        final extDirs = await getExternalCacheDirectories();
        if (extDirs != null) {
          for (final dir in extDirs) {
            if (await dir.exists()) {
              final entities = dir.listSync(recursive: false);
              for (final entity in entities) {
                try {
                  entity.deleteSync(recursive: true);
                } catch (_) {}
              }
            }
          }
        }
      } catch (e) {
        debugPrint('[AppCacheService] Error clearing external cache: $e');
      }
    }

    // 3. Flutter image memory and network disk cache
    try {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
    } catch (_) {}

    try {
      await CachedNetworkImageProvider.defaultCacheManager.emptyCache();
    } catch (e) {
      debugPrint('[AppCacheService] Error clearing CachedNetworkImage cache: $e');
    }

    // 4. SecureAttachmentService in-memory and local cache
    try {
      SecureAttachmentService.clearInMemoryCache();
    } catch (_) {}

    // 5. App documents internal Schat cache
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final schatDir = Directory('${appDir.path}/Schat');
      if (await schatDir.exists()) {
        final entities = schatDir.listSync(recursive: false);
        for (final entity in entities) {
          try {
            entity.deleteSync(recursive: true);
          } catch (_) {}
        }
      }
      final tempSchatDir = Directory('${appDir.path}/temp');
      if (await tempSchatDir.exists()) {
        await tempSchatDir.delete(recursive: true);
      }
    } catch (e) {
      debugPrint('[AppCacheService] Error clearing documents cache: $e');
    }

    // 6. External storage residual cache (Android legacy folders)
    if (Platform.isAndroid && wipeExternalResidual) {
      final residualDirs = [
        Directory('/storage/emulated/0/Download/Schat'),
        Directory('/storage/emulated/0/Schat'),
        Directory('/storage/emulated/0/Pictures/Schat/temp'),
      ];
      for (final dir in residualDirs) {
        try {
          if (await dir.exists()) {
            final entities = dir.listSync(recursive: false);
            for (final entity in entities) {
              try {
                entity.deleteSync(recursive: true);
              } catch (_) {}
            }
          }
        } catch (_) {}
      }
    }
  }

  /// Calculates total size of cached files in bytes across temporary and app cache directories.
  static Future<int> getCacheSizeBytes() async {
    if (kIsWeb) return 0;
    int totalBytes = 0;

    try {
      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        await for (final file in tempDir.list(recursive: true, followLinks: false)) {
          if (file is File) {
            try {
              totalBytes += await file.length();
            } catch (_) {}
          }
        }
      }
    } catch (_) {}

    if (Platform.isAndroid) {
      try {
        final extCacheDirs = await getExternalCacheDirectories();
        if (extCacheDirs != null) {
          for (final dir in extCacheDirs) {
            if (await dir.exists()) {
              await for (final file in dir.list(recursive: true, followLinks: false)) {
                if (file is File) {
                  try {
                    totalBytes += await file.length();
                  } catch (_) {}
                }
              }
            }
          }
        }
      } catch (_) {}
    }

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final schatDir = Directory('${appDir.path}/Schat');
      if (await schatDir.exists()) {
        await for (final file in schatDir.list(recursive: true, followLinks: false)) {
          if (file is File) {
            try {
              totalBytes += await file.length();
            } catch (_) {}
          }
        }
      }
    } catch (_) {}

    return totalBytes;
  }

  /// Returns a human-readable formatted string for a byte count (e.g. "14.2 MB").
  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = (math.log(bytes) / math.log(1024)).floor();
    if (i >= suffixes.length) i = suffixes.length - 1;
    final num = bytes / math.pow(1024, i);
    return '${num.toStringAsFixed(1)} ${suffixes[i]}';
  }
}
