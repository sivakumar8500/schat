import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:schat/injection.dart';
import 'package:schat/core/security/secure_attachment_service.dart';
import 'package:schat/core/security/screen_protection_service.dart';

/// Represents the live status of an ongoing or completed download task.
class DownloadTaskInfo {
  final String id;
  final String url;
  final String fileName;
  final int notificationId;
  final double progress; // 0.0 to 1.0
  final int receivedBytes;
  final int totalBytes;
  final bool isDownloading;
  final bool isCompleted;
  final String? error;
  final File? savedFile;

  DownloadTaskInfo({
    required this.id,
    required this.url,
    required this.fileName,
    required this.notificationId,
    this.progress = 0.0,
    this.receivedBytes = 0,
    this.totalBytes = 0,
    this.isDownloading = true,
    this.isCompleted = false,
    this.error,
    this.savedFile,
  });

  DownloadTaskInfo copyWith({
    double? progress,
    int? receivedBytes,
    int? totalBytes,
    bool? isDownloading,
    bool? isCompleted,
    String? error,
    File? savedFile,
  }) {
    return DownloadTaskInfo(
      id: id,
      url: url,
      fileName: fileName,
      notificationId: notificationId,
      progress: progress ?? this.progress,
      receivedBytes: receivedBytes ?? this.receivedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      isDownloading: isDownloading ?? this.isDownloading,
      isCompleted: isCompleted ?? this.isCompleted,
      error: error ?? this.error,
      savedFile: savedFile ?? this.savedFile,
    );
  }
}

/// Service that orchestrates file downloads, ensures background execution
/// when the app is minimized (via WakeLocks on Android and background tasks on iOS),
/// and displays real-time progress notifications in the notification bar with percentage.
class BackgroundDownloadService {
  static final BackgroundDownloadService instance = BackgroundDownloadService._internal();
  BackgroundDownloadService._internal();

  static const String channelId = 'schat_downloads_channel';
  static const String channelName = 'File Downloads';

  static const MethodChannel _platformChannel = MethodChannel('com.sdpi.schat/screenshot_detector');
  static const MethodChannel _iosBgChannel = MethodChannel('com.sdpi.schat/background_tasks');

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  final Map<String, DownloadTaskInfo> _activeTasks = {};
  final Map<String, Completer<File?>> _inFlightCompleters = {};
  final Map<String, int> _lastNotificationTimestamps = {};
  final StreamController<DownloadTaskInfo> _taskStreamController = StreamController<DownloadTaskInfo>.broadcast();

  Stream<DownloadTaskInfo> get taskStream => _taskStreamController.stream;

  bool get hasActiveDownloads => _activeTasks.values.any((t) => t.isDownloading);

  List<int> get activeNotificationIds =>
      _activeTasks.values.where((t) => t.isDownloading).map((t) => t.notificationId).toList();

  DownloadTaskInfo? getTask(String urlOrId) {
    if (urlOrId.isEmpty) return null;
    if (_activeTasks.containsKey(urlOrId)) return _activeTasks[urlOrId];
    for (final task in _activeTasks.values) {
      if (task.url == urlOrId || task.fileName == urlOrId) {
        return task;
      }
    }
    return null;
  }

  bool _initialized = false;
  int _activeDownloadCount = 0;

  /// Initializes the dedicated download notification channel on Android.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    if (!kIsWeb && Platform.isAndroid) {
      try {
        final androidPlugin = _localNotifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlugin != null) {
          final channel = AndroidNotificationChannel(
            channelId,
            channelName,
            description: 'Ongoing notifications for file download progress and completion',
            importance: Importance.low,
            playSound: false,
            enableVibration: false,
            showBadge: false,
          );
          await androidPlugin.createNotificationChannel(channel);
          debugPrint('BackgroundDownloadService: Created Android notification channel "$channelId"');
        }
      } catch (e) {
        debugPrint('BackgroundDownloadService: Error creating notification channel: $e');
      }
    }
  }

  /// Initiates or connects to an in-flight background download.
  Future<File?> download({
    required String url,
    required String fileName,
    void Function(int count, int total)? onProgress,
  }) async {
    if (kIsWeb) {
      return null;
    }

    await initialize();

    final cleanUrl = SecureAttachmentService.resolveFullUrl(url);
    if (cleanUrl.isEmpty) {
      debugPrint('BackgroundDownloadService: Error - empty URL provided');
      return null;
    }

    final taskKey = cleanUrl;

    // Deduplicate in-flight download for identical URL
    if (_inFlightCompleters.containsKey(taskKey)) {
      debugPrint('BackgroundDownloadService: Download already in flight for $cleanUrl, joining...');
      return await _inFlightCompleters[taskKey]!.future;
    }

    final completer = Completer<File?>();
    _inFlightCompleters[taskKey] = completer;

    final notificationId = 20000 + (cleanUrl.hashCode.abs() % 10000);

    var cleanDisplayName = fileName.trim();
    if (cleanDisplayName.contains('?')) {
      cleanDisplayName = cleanDisplayName.split('?').first.trim();
    }
    if (cleanDisplayName.contains('/')) {
      cleanDisplayName = cleanDisplayName.split('/').last.trim();
    }
    if (cleanDisplayName.isEmpty || cleanDisplayName == 'File' || cleanDisplayName == 'downloaded_file') {
      final urlName = cleanUrl.split('?').first.split('/').last.trim();
      if (urlName.isNotEmpty && urlName.contains('.')) {
        cleanDisplayName = urlName;
      } else {
        cleanDisplayName = 'Attachment_${DateTime.now().millisecondsSinceEpoch}';
      }
    }

    var task = DownloadTaskInfo(
      id: taskKey,
      url: cleanUrl,
      fileName: cleanDisplayName,
      notificationId: notificationId,
      progress: 0.05,
      isDownloading: true,
    );
    _activeTasks[taskKey] = task;
    _taskStreamController.add(task);

    await _acquireBackgroundLock();

    // Show initial progress notification (0%)
    await _updateProgressNotification(task);

    try {
      final secureService = getIt<SecureAttachmentService>();

      // 1. Download and securely encrypt attachment with AES-256
      final encryptedFile = await secureService.downloadAndEncryptAttachment(
        url: cleanUrl,
        fileName: cleanDisplayName,
        onProgress: (received, total) {
          final double progressRatio = total > 0 ? (received / total).clamp(0.0, 1.0) : 0.0;
          task = task.copyWith(
            progress: progressRatio,
            receivedBytes: received,
            totalBytes: total,
            isDownloading: true,
          );
          _activeTasks[taskKey] = task;
          _taskStreamController.add(task);
          onProgress?.call(received, total);

          // Throttled notification update to avoid Android notification flood
          _throttleProgressNotification(task);
        },
      );

      if (!await encryptedFile.exists()) {
        throw Exception('Downloaded encrypted file does not exist');
      }

      final encryptedBytes = await encryptedFile.readAsBytes();

      // 2. Determine target .enc filename
      var targetEncName = cleanDisplayName;
      if (!targetEncName.toLowerCase().endsWith('.enc')) {
        targetEncName = '$targetEncName.enc';
      }

      File? savedPublicFile;

      // 3. Save encrypted .enc file to public /storage/emulated/0/Download/Schat on Android
      if (Platform.isAndroid) {
        try {
          final schatDir = Directory('/storage/emulated/0/Download/Schat');
          if (!await schatDir.exists()) {
            await schatDir.create(recursive: true);
          }
          final target = File('${schatDir.path}/$targetEncName');
          await target.writeAsBytes(encryptedBytes, flush: true);
          savedPublicFile = target;
          debugPrint('BackgroundDownloadService: Saved encrypted .enc file to public path -> ${target.path}');
        } catch (e) {
          debugPrint('BackgroundDownloadService: Direct save error: $e');
        }

        // 4. MediaStore.Downloads
        try {
          final String? nativeSavedPath = await _platformChannel.invokeMethod<String>('saveFileToDownloads', {
            'bytes': encryptedBytes,
            'fileName': targetEncName,
            'mimeType': 'application/octet-stream',
          });
          if (nativeSavedPath != null && nativeSavedPath.isNotEmpty) {
            final f = File(nativeSavedPath);
            if (await f.exists()) {
              savedPublicFile = f;
            }
          }
        } catch (e) {
          debugPrint('BackgroundDownloadService: Native MediaStore channel error: $e');
        }

        // 5. MediaScanner
        if (savedPublicFile != null) {
          try {
            if (getIt.isRegistered<ScreenProtectionService>()) {
              await getIt<ScreenProtectionService>().scanFile(savedPublicFile.path);
            }
          } catch (_) {}
        }
      }

      final effectiveFile = savedPublicFile ?? encryptedFile;

      // 6. Cache mappings
      SecureAttachmentService.cacheMediaMapping(key: cleanUrl, localPath: effectiveFile.path);
      SecureAttachmentService.cacheMediaMapping(key: cleanDisplayName, localPath: effectiveFile.path);
      SecureAttachmentService.cacheMediaMapping(key: targetEncName, localPath: effectiveFile.path);

      try {
        await secureService.saveToPersistentStorage(
          originalPath: effectiveFile.path,
          fileName: targetEncName,
          bytes: encryptedBytes,
        );
      } catch (_) {}

      // 7. Success state and notification
      task = task.copyWith(
        progress: 1.0,
        isDownloading: false,
        isCompleted: true,
        savedFile: effectiveFile,
      );
      _activeTasks[taskKey] = task;
      _taskStreamController.add(task);

      await _showCompleteNotification(task);
      completer.complete(effectiveFile);
      return effectiveFile;
    } catch (e) {
      debugPrint('BackgroundDownloadService: Error downloading $cleanUrl: $e');
      task = task.copyWith(
        isDownloading: false,
        isCompleted: false,
        error: e.toString(),
      );
      _activeTasks[taskKey] = task;
      _taskStreamController.add(task);

      await _showFailedNotification(task);
      completer.complete(null);
      return null;
    } finally {
      _inFlightCompleters.remove(taskKey);
      await _releaseBackgroundLock();
    }
  }

  /// Throttles notification updates to at most once every 350ms or when reaching 100%.
  void _throttleProgressNotification(DownloadTaskInfo task) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final lastTime = _lastNotificationTimestamps[task.id] ?? 0;
    if (now - lastTime >= 350 || task.progress >= 0.99) {
      _lastNotificationTimestamps[task.id] = now;
      _updateProgressNotification(task);
    }
  }

  /// Updates ongoing progress notification in the notification bar with percentage.
  Future<void> _updateProgressNotification(DownloadTaskInfo task) async {
    try {
      final int percent = (task.progress * 100).toInt().clamp(0, 100);
      String sizeInfo = '';
      if (task.totalBytes > 0) {
        sizeInfo = ' • ${_formatBytes(task.receivedBytes)} / ${_formatBytes(task.totalBytes)}';
      } else if (task.receivedBytes > 0) {
        sizeInfo = ' • ${_formatBytes(task.receivedBytes)}';
      }

      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: 'Notifications for file download progress and completion',
        importance: Importance.low,
        priority: Priority.low,
        showProgress: true,
        maxProgress: 100,
        progress: percent,
        ongoing: true,
        onlyAlertOnce: true,
        autoCancel: false,
        playSound: false,
        enableVibration: false,
        category: AndroidNotificationCategory.progress,
      );

      final darwinDetails = DarwinNotificationDetails(
        presentAlert: false,
        presentBadge: false,
        presentSound: false,
        subtitle: '$percent% downloaded',
      );

      await _localNotifications.show(
        id: task.notificationId,
        title: 'Downloading ${task.fileName}',
        body: '$percent%$sizeInfo',
        notificationDetails: NotificationDetails(android: androidDetails, iOS: darwinDetails),
        payload: jsonEncode({
          'type': 'download_progress',
          'url': task.url,
          'fileName': task.fileName,
        }),
      );
    } catch (e) {
      debugPrint('BackgroundDownloadService: Error updating progress notification: $e');
    }
  }

  /// Shows the download complete notification and removes ongoing flag.
  Future<void> _showCompleteNotification(DownloadTaskInfo task) async {
    try {
      final androidDetails = const AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: 'Notifications for file download progress and completion',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        showProgress: false,
        ongoing: false,
        autoCancel: true,
        category: AndroidNotificationCategory.status,
      );

      final darwinDetails = const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: true,
      );

      await _localNotifications.show(
        id: task.notificationId,
        title: 'Download complete',
        body: task.fileName,
        notificationDetails: NotificationDetails(android: androidDetails, iOS: darwinDetails),
        payload: jsonEncode({
          'type': 'download_complete',
          'url': task.url,
          'fileName': task.fileName,
          'filePath': task.savedFile?.path,
        }),
      );
    } catch (e) {
      debugPrint('BackgroundDownloadService: Error showing complete notification: $e');
    }
  }

  /// Shows the download failed notification.
  Future<void> _showFailedNotification(DownloadTaskInfo task) async {
    try {
      final androidDetails = const AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: 'Notifications for file download progress and completion',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        showProgress: false,
        ongoing: false,
        autoCancel: true,
      );

      final darwinDetails = const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: true,
      );

      await _localNotifications.show(
        id: task.notificationId,
        title: 'Download failed',
        body: 'Could not download ${task.fileName}',
        notificationDetails: NotificationDetails(android: androidDetails, iOS: darwinDetails),
        payload: jsonEncode({
          'type': 'download_failed',
          'url': task.url,
          'fileName': task.fileName,
        }),
      );
    } catch (e) {
      debugPrint('BackgroundDownloadService: Error showing failed notification: $e');
    }
  }

  /// Re-posts active ongoing progress notifications if cleared by FCM or system.
  void repostActiveNotifications() {
    for (final task in _activeTasks.values) {
      if (task.isDownloading) {
        _updateProgressNotification(task);
      }
    }
  }

  /// Acquires background locks to prevent CPU sleep / socket pause when app is minimized.
  Future<void> _acquireBackgroundLock() async {
    _activeDownloadCount++;
    if (_activeDownloadCount == 1) {
      try {
        await WakelockPlus.enable();
      } catch (_) {}

      if (!kIsWeb && Platform.isAndroid) {
        try {
          await _platformChannel.invokeMethod('acquireDownloadWakeLock');
        } catch (_) {}
      } else if (!kIsWeb && Platform.isIOS) {
        try {
          await _iosBgChannel.invokeMethod('beginBackgroundTask');
        } catch (_) {}
      }
    }
  }

  /// Releases background locks when all downloads finish.
  Future<void> _releaseBackgroundLock() async {
    _activeDownloadCount--;
    if (_activeDownloadCount <= 0) {
      _activeDownloadCount = 0;
      try {
        await WakelockPlus.disable();
      } catch (_) {}

      if (!kIsWeb && Platform.isAndroid) {
        try {
          await _platformChannel.invokeMethod('releaseDownloadWakeLock');
        } catch (_) {}
      } else if (!kIsWeb && Platform.isIOS) {
        try {
          await _iosBgChannel.invokeMethod('endBackgroundTask');
        } catch (_) {}
      }
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = (log(bytes) / log(1024)).floor();
    if (i >= suffixes.length) i = suffixes.length - 1;
    return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }
}
