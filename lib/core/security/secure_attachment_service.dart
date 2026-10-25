import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:schat/core/storage/storage_service.dart';
import 'package:schat/core/security/screen_protection_service.dart';
import 'package:schat/injection.dart';
import 'package:schat/utils/common_endpoints.dart';
import 'package:schat/utils/download_helper/download_helper.dart';

@lazySingleton
class SecureAttachmentService {
  final StorageService _storageService;
  final Dio _cleanDio;

  SecureAttachmentService(this._storageService)
      : _cleanDio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
          followRedirects: true,
          maxRedirects: 5,
          validateStatus: (status) => status != null && status >= 200 && status < 300,
        ));

  static final Map<String, String> _mediaKeyToLocalPath = {};
  static final Map<String, String> _mediaKeyToMediaId = {};
  static String? _cachedDocsPath;

  /// Cache mapping of a media key/filename to its local file path and optional mediaId.
  static void cacheMediaMapping({required String key, String? localPath, String? mediaId}) {
    if (key.trim().isEmpty) return;
    final cleanKey = key.trim();
    if (localPath != null && localPath.isNotEmpty) {
      _mediaKeyToLocalPath[cleanKey] = localPath;
      final lastPart = cleanKey.split('/').last;
      _mediaKeyToLocalPath[lastPart] = localPath;
      var stripped = lastPart;
      while (stripped.toLowerCase().endsWith('.enc')) {
        stripped = stripped.substring(0, stripped.length - 4);
        _mediaKeyToLocalPath[stripped] = localPath;
      }
    }
    if (mediaId != null && mediaId.isNotEmpty) {
      _mediaKeyToMediaId[cleanKey] = mediaId;
      _mediaKeyToMediaId[cleanKey.split('/').last] = mediaId;
    }
  }

  /// Look up cached local path by key or fileName.
  static String? findCachedLocalPath(String? key) {
    if (key == null || key.trim().isEmpty) return null;
    final cleanKey = key.trim();
    var path = _mediaKeyToLocalPath[cleanKey] ?? _mediaKeyToLocalPath[cleanKey.split('/').last];
    if (path != null && !kIsWeb && File(path).existsSync()) return path;
    return null;
  }

  /// Look up cached mediaId by key or fileName.
  static String? findMediaId(String? key) {
    if (key == null || key.trim().isEmpty) return null;
    final cleanKey = key.trim();
    return _mediaKeyToMediaId[cleanKey] ?? _mediaKeyToMediaId[cleanKey.split('/').last];
  }

  /// Synchronously probe candidate local storage directories to locate an attachment on device disk.
  static String? findLocalFile({String? pathOrKey, String? fileName}) {
    if (kIsWeb) return null;

    // 1. Direct check if pathOrKey is already a valid local path
    if (pathOrKey != null && pathOrKey.isNotEmpty) {
      final clean = pathOrKey.replaceAll('file://', '').trim();
      if ((clean.startsWith('/') || clean.contains(':\\')) && File(clean).existsSync()) {
        return clean;
      }
    }

    // 2. In-memory cache check
    final fromCache = findCachedLocalPath(pathOrKey) ?? findCachedLocalPath(fileName);
    if (fromCache != null && File(fromCache).existsSync()) {
      return fromCache;
    }

    // 3. Name candidates
    final List<String> nameCandidates = [];
    void addCandidate(String? name) {
      if (name == null || name.trim().isEmpty) return;
      var c = name.trim().split('/').last;
      if (c.isNotEmpty && !nameCandidates.contains(c)) nameCandidates.add(c);
      var stripped = c;
      while (stripped.toLowerCase().endsWith('.enc')) {
        stripped = stripped.substring(0, stripped.length - 4);
        if (stripped.isNotEmpty && !nameCandidates.contains(stripped)) nameCandidates.add(stripped);
      }
      if (!c.toLowerCase().endsWith('.enc') && !nameCandidates.contains('$c.enc')) {
        nameCandidates.add('$c.enc');
      }
    }

    addCandidate(fileName);
    addCandidate(pathOrKey);

    if (nameCandidates.isEmpty) return null;

    // 4. Directory candidates
    final List<String> dirCandidates = [];
    try {
      final sysTemp = Directory.systemTemp;
      dirCandidates.add('${sysTemp.parent.path}/Documents/Schat');
      dirCandidates.add('${sysTemp.path}/schat/temp');
      dirCandidates.add('${sysTemp.path}/schat');
    } catch (_) {}

    if (Platform.isAndroid) {
      dirCandidates.add('/storage/emulated/0/Download/Schat');
      dirCandidates.add('/storage/emulated/0/Schat');
    }

    if (_cachedDocsPath != null && _cachedDocsPath!.isNotEmpty) {
      dirCandidates.add(_cachedDocsPath!);
    }

    for (final dirPath in dirCandidates) {
      try {
        final dir = Directory(dirPath);
        if (dir.existsSync()) {
          for (final cand in nameCandidates) {
            final f = File('${dir.path}/$cand');
            if (f.existsSync() && f.lengthSync() > 0) {
              final foundPath = f.path;
              if (pathOrKey != null) cacheMediaMapping(key: pathOrKey, localPath: foundPath);
              if (fileName != null) cacheMediaMapping(key: fileName, localPath: foundPath);
              return foundPath;
            }
          }
        }
      } catch (_) {}
    }

    return null;
  }

  /// Resolve relative paths into full S3 or MinIO URLs.
  static String resolveFullUrl(String path) {
    if (path.isEmpty) return '';
    var cleanPath = path.replaceAll('file://', '').trim();
    if (cleanPath.startsWith('http://') || cleanPath.startsWith('https://')) {
      var resolved = cleanPath;
      try {
        final serverUri = Uri.parse(CommonEndpoints.baseUrl);
        var host = serverUri.host;
        if (!kIsWeb && Platform.isAndroid && (host == 'localhost' || host == '127.0.0.1' || host.isEmpty)) {
          host = '10.0.2.2';
        }
        if (resolved.contains('minio')) {
          resolved = resolved.replaceAll('minio', host);
        }
        if (!kIsWeb && Platform.isAndroid) {
          resolved = resolved.replaceAll('localhost', '10.0.2.2').replaceAll('127.0.0.1', '10.0.2.2');
        }
      } catch (_) {}
      return resolved;
    }
    if (!kIsWeb && File(cleanPath).existsSync()) {
      return cleanPath;
    }

    // Check if cleanPath is a local file path that no longer exists on disk (e.g. wiped /tmp cache)
    final bool isDeadLocalPath = cleanPath.startsWith('/private/') ||
        cleanPath.startsWith('/var/') ||
        cleanPath.startsWith('/tmp/') ||
        cleanPath.startsWith('/data/') ||
        cleanPath.startsWith('/storage/') ||
        cleanPath.startsWith('/Users/') ||
        cleanPath.contains('Containers/Data/Application') ||
        cleanPath.contains('image_picker');

    if (isDeadLocalPath) {
      // Under NO circumstances prepend S3 base URL to a dead local device path!
      return '';
    }

    String s3BaseUrl;
    try {
      final serverUri = Uri.parse(CommonEndpoints.baseUrl);
      var host = serverUri.host;
      if (!kIsWeb && Platform.isAndroid && (host == 'localhost' || host == '127.0.0.1' || host.isEmpty)) {
        host = '10.0.2.2';
      }
      final scheme = serverUri.scheme.isNotEmpty ? serverUri.scheme : 'http';
      if (host.isNotEmpty && (host == 'localhost' || host == '127.0.0.1' || host == '10.0.2.2')) {
        s3BaseUrl = '$scheme://$host:9000/qlyncs-doc/';
      } else {
        s3BaseUrl = 'https://qlyncs-doc.s3.ap-south-1.amazonaws.com/';
      }
    } catch (_) {
      s3BaseUrl = 'https://qlyncs-doc.s3.ap-south-1.amazonaws.com/';
    }

    while (cleanPath.startsWith('/')) {
      cleanPath = cleanPath.substring(1);
    }
    if (cleanPath.startsWith('minio:9000/qlyncs-doc/')) {
      cleanPath = cleanPath.replaceFirst('minio:9000/qlyncs-doc/', '');
    } else if (cleanPath.startsWith('minio:9000/')) {
      cleanPath = cleanPath.replaceFirst('minio:9000/', '');
    } else if (cleanPath.startsWith('minio/')) {
      cleanPath = cleanPath.replaceFirst('minio/', '');
    }
    if (cleanPath.startsWith('qlyncs-doc/')) {
      cleanPath = cleanPath.replaceFirst('qlyncs-doc/', '');
    } else if (cleanPath.startsWith('qlyncs-docs/')) {
      cleanPath = cleanPath.replaceFirst('qlyncs-docs/', '');
    }
    return '$s3BaseUrl$cleanPath';
  }

  String _resolveFullUrl(String path) => resolveFullUrl(path);

  /// Derive 256-bit (32-byte) AES key based on user and device identity.
  enc.Key _getEncryptionKey() {
    final userId = _storageService.getUserId() ?? 'guest_user';
    final deviceId = _storageService.getOrGenerateDeviceId();
    final rawSeed = 'schat_sec_attachment_${userId}_$deviceId';
    final keyBytes = sha256.convert(utf8.encode(rawSeed)).bytes;
    return enc.Key(Uint8List.fromList(keyBytes));
  }

  enc.Key _getFallbackKeyUserOnly() {
    final userId = _storageService.getUserId() ?? 'guest_user';
    final rawSeed = 'schat_sec_attachment_$userId';
    final keyBytes = sha256.convert(utf8.encode(rawSeed)).bytes;
    return enc.Key(Uint8List.fromList(keyBytes));
  }

  enc.Key _getFallbackKeyCommon() {
    const rawSeed = 'schat_sec_attachment_common_key';
    final keyBytes = sha256.convert(utf8.encode(rawSeed)).bytes;
    return enc.Key(Uint8List.fromList(keyBytes));
  }

  enc.Key _getFallbackKeyGuestDevice() {
    final deviceId = _storageService.getOrGenerateDeviceId();
    final rawSeed = 'schat_sec_attachment_guest_user_$deviceId';
    final keyBytes = sha256.convert(utf8.encode(rawSeed)).bytes;
    return enc.Key(Uint8List.fromList(keyBytes));
  }

  enc.Key _getFallbackKeyGuest() {
    const rawSeed = 'schat_sec_attachment_guest_user';
    final keyBytes = sha256.convert(utf8.encode(rawSeed)).bytes;
    return enc.Key(Uint8List.fromList(keyBytes));
  }

  /// Gather all possible AES encryption keys that could have encrypted files on this or prior sessions/devices.
  List<enc.Key> _getAllCandidateKeys() {
    final List<String> seeds = [];
    final userId = _storageService.getUserId();
    final deviceId = _storageService.getOrGenerateDeviceId();
    final phone = _storageService.getPhoneNumber();
    final username = _storageService.getUsername();

    if (userId != null && userId.isNotEmpty) {
      seeds.add('schat_sec_attachment_${userId}_$deviceId');
      seeds.add('schat_sec_attachment_$userId');
      seeds.add('schat_attachment_${userId}_$deviceId');
      seeds.add('schat_attachment_$userId');
      seeds.add('schat_sec_attachment_${userId}_');
    }
    if (phone != null && phone.isNotEmpty) {
      seeds.add('schat_sec_attachment_${phone}_$deviceId');
      seeds.add('schat_sec_attachment_$phone');
      seeds.add('schat_attachment_${phone}_$deviceId');
      seeds.add('schat_attachment_$phone');
    }
    if (username != null && username.isNotEmpty) {
      seeds.add('schat_sec_attachment_$username');
      seeds.add('schat_sec_attachment_${username}_$deviceId');
      seeds.add('schat_attachment_$username');
    }

    seeds.add('schat_sec_attachment_guest_user_$deviceId');
    seeds.add('schat_sec_attachment_guest_user');
    seeds.add('schat_sec_attachment_$deviceId');
    seeds.add('schat_sec_attachment_common_key');
    seeds.add('schat_sec_attachment');
    seeds.add('schat_attachment_common_key');
    seeds.add('schat_attachment_secret_key');
    seeds.add('schat_default_encryption_key');
    seeds.add('schat_sec_attachment_default_key');
    seeds.add('schat_encryption_key');

    final List<enc.Key> keys = [];
    final Set<String> seenHashes = {};

    for (final seed in seeds) {
      final keyBytes = sha256.convert(utf8.encode(seed)).bytes;
      final hashStr = keyBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      if (!seenHashes.contains(hashStr)) {
        seenHashes.add(hashStr);
        keys.add(enc.Key(Uint8List.fromList(keyBytes)));
      }
    }
    return keys;
  }

  bool _isPlaintextFile(Uint8List bytes, String safeName) {
    if (bytes.length < 4) return false;
    final lower = safeName.toLowerCase();

    // Check magic bytes directly regardless of file name/extension
    // PDF: %PDF
    if (bytes.length >= 4 && bytes[0] == 0x25 && bytes[1] == 0x50 && bytes[2] == 0x44 && bytes[3] == 0x46) {
      return true;
    }
    // JPEG: 0xFF, 0xD8, 0xFF
    if (bytes.length >= 3 && bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return true;
    }
    // PNG: 0x89, 'PNG'
    if (bytes.length >= 4 && bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
      return true;
    }
    // GIF: 'GIF8'
    if (bytes.length >= 4 && bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x38) {
      return true;
    }
    // WEBP: 'RIFF'...'WEBP'
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 &&
        bytes[8] == 0x57 && bytes[9] == 0x45 && bytes[10] == 0x42 && bytes[11] == 0x50) {
      return true;
    }
    // MP4 / M4A / MOV: ftyp box at byte 4
    if (bytes.length >= 8 &&
        bytes[4] == 0x66 && bytes[5] == 0x74 && bytes[6] == 0x79 && bytes[7] == 0x70) {
      return true; // 'ftyp'
    }
    // MP3: ID3 header ('ID3') or sync word (0xFFE0 mask)
    if (bytes[0] == 0x49 && bytes[1] == 0x44 && bytes[2] == 0x33) return true;
    if (bytes[0] == 0xFF && (bytes[1] & 0xE0) == 0xE0) return true;
    // WAV: 'RIFF' .... 'WAVE'
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 &&
        bytes[8] == 0x57 && bytes[9] == 0x41 && bytes[10] == 0x56 && bytes[11] == 0x45) {
      return true;
    }
    // ZIP / Office docx, xlsx, pptx: PK\x03\x04
    if (bytes.length >= 4 && bytes[0] == 0x50 && bytes[1] == 0x4B && bytes[2] == 0x03 && bytes[3] == 0x04) {
      return true;
    }
    // Matroska / WebM: 0x1A 0x45 0xDF 0xA3
    if (bytes.length >= 4 && bytes[0] == 0x1A && bytes[1] == 0x45 && bytes[2] == 0xDF && bytes[3] == 0xA3) {
      return true;
    }

    // Extension-matched checks
    if (lower.endsWith('.mp3')) {
      if (bytes[0] == 0x49 && bytes[1] == 0x44 && bytes[2] == 0x33) return true;
      if (bytes[0] == 0xFF && (bytes[1] & 0xE0) == 0xE0) return true;
    }
    if (lower.endsWith('.wav')) {
      if (bytes.length >= 12 &&
          bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 &&
          bytes[8] == 0x57 && bytes[9] == 0x41 && bytes[10] == 0x56 && bytes[11] == 0x45) {
        return true;
      }
    }
    if (lower.endsWith('.mp4') || lower.endsWith('.m4a') || lower.endsWith('.mov')) {
      if (bytes.length >= 8 &&
          bytes[4] == 0x66 && bytes[5] == 0x74 && bytes[6] == 0x79 && bytes[7] == 0x70) {
        return true;
      }
    }
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) return true;
    }
    if (lower.endsWith('.png')) {
      if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) return true;
    }
    if (lower.endsWith('.pdf')) {
      if (bytes[0] == 0x25 && bytes[1] == 0x50 && bytes[2] == 0x44 && bytes[3] == 0x46) return true;
    }

    return false;
  }

  Future<Directory> _getSecureStorageDir() async {
    if (kIsWeb) {
      throw UnsupportedError('Secure Storage Directory is not supported on Web');
    }
    Directory? storageDir;
    if (Platform.isAndroid) {
      final downloadSchat = Directory('/storage/emulated/0/Download/Schat');
      try {
        if (!await downloadSchat.exists()) {
          await downloadSchat.create(recursive: true);
        }
        storageDir = downloadSchat;
      } catch (e) {
        debugPrint('SecureAttachmentService: Download/Schat storage fallback ($e)');
        final rootSchat = Directory('/storage/emulated/0/Schat');
        try {
          if (!await rootSchat.exists()) {
            await rootSchat.create(recursive: true);
          }
          storageDir = rootSchat;
        } catch (_) {}
      }

      if (storageDir == null) {
        final extDir = await getExternalStorageDirectory();
        if (extDir != null) {
          final schatExt = Directory('${extDir.path}/Schat');
          if (!await schatExt.exists()) {
            await schatExt.create(recursive: true);
          }
          storageDir = schatExt;
        }
      }
    } else if (Platform.isIOS) {
      final appDir = await getApplicationDocumentsDirectory();
      final schatDir = Directory('${appDir.path}/Schat');
      if (!await schatDir.exists()) {
        await schatDir.create(recursive: true);
      }
      storageDir = schatDir;
    }

    if (storageDir == null) {
      final appDir = await getApplicationDocumentsDirectory();
      final schatDir = Directory('${appDir.path}/Schat');
      if (!await schatDir.exists()) {
        await schatDir.create(recursive: true);
      }
      storageDir = schatDir;
    }
    _cachedDocsPath = storageDir.path;
    return storageDir;
  }

  Future<Directory> _getTempDir() async {
    if (kIsWeb) {
      throw UnsupportedError('Temp Directory is not supported on Web');
    }
    final tempDir = await getTemporaryDirectory();
    final decryptDir = Directory('${tempDir.path}/schat/temp');
    if (!await decryptDir.exists()) {
      await decryptDir.create(recursive: true);
    }
    return decryptDir;
  }

  String _getEncryptedFileName(String fileName, String identifier) {
    var cleanName = fileName.replaceAll(RegExp(r'[^\w\.\-]'), '_');
    if (cleanName.isEmpty || cleanName == 'File') {
      final hash = sha256.convert(utf8.encode(identifier)).toString().substring(0, 12);
      cleanName = 'attachment_$hash';
    }
    if (!cleanName.endsWith('.enc')) {
      cleanName = '$cleanName.enc';
    }
    return cleanName;
  }

  Future<bool> isAttachmentCached(String identifier, [String? fileName]) async {
    if (kIsWeb) return false;
    try {
      final secureDir = await _getSecureStorageDir();
      final encFileName = _getEncryptedFileName(fileName ?? 'File', identifier);
      final rawWithoutEnc = encFileName.endsWith('.enc')
          ? encFileName.substring(0, encFileName.length - 4)
          : encFileName;
      final file1 = File('${secureDir.path}/$encFileName');
      final file2 = File('${secureDir.path}/$rawWithoutEnc');
      if (await file1.exists() || await file2.exists()) return true;

      if (fileName != null && fileName.isNotEmpty && fileName != 'File') {
        final fallbackEnc = _getEncryptedFileName('File', identifier);
        final file3 = File('${secureDir.path}/$fallbackEnc');
        if (await file3.exists()) return true;
      }

      if (Platform.isAndroid) {
        final legacy1 = File('/storage/emulated/0/Download/Schat/$encFileName');
        final legacy2 = File('/storage/emulated/0/Download/Schat/$rawWithoutEnc');
        if (await legacy1.exists() || await legacy2.exists()) return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Checks if downloaded or decrypted bytes represent an HTML/XML/JSON error page.
  static bool _isErrorResponse(Uint8List bytes) {
    if (bytes.isEmpty) return true;
    final checkLen = bytes.length < 512 ? bytes.length : 512;
    final snippet = utf8.decode(bytes.sublist(0, checkLen), allowMalformed: true).trim().toLowerCase();
    return snippet.startsWith('<?xml') ||
        snippet.startsWith('<!doctype') ||
        snippet.startsWith('<html') ||
        snippet.startsWith('<error') ||
        snippet.contains('<error><code') ||
        snippet.contains('nosuchkey') ||
        snippet.contains('accessdenied') ||
        snippet.startsWith('{"detail":') ||
        snippet.startsWith('{"message":') ||
        snippet.startsWith('{"status":') ||
        snippet.startsWith('{"error":') ||
        snippet.startsWith('{"statuscode":');
  }

  /// Verifies whether an encrypted cached file is actually an encrypted error response.
  Future<bool> _isCorruptEncryptedFile(File file) async {
    try {
      final bytes = await file.readAsBytes();
      if (bytes.length < 16) return true;
      if (_isErrorResponse(bytes)) return true;

      final iv = enc.IV(bytes.sublist(0, 16));
      final cipherBytes = bytes.sublist(16);
      if (cipherBytes.isEmpty) return true;

      final key = _getEncryptionKey();
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      try {
        final decrypted = encrypter.decryptBytes(enc.Encrypted(cipherBytes), iv: iv);
        return _isErrorResponse(Uint8List.fromList(decrypted));
      } catch (_) {
        final fallbackKey = _getFallbackKeyCommon();
        final encrypterFallback = enc.Encrypter(enc.AES(fallbackKey, mode: enc.AESMode.cbc));
        try {
          final decrypted = encrypterFallback.decryptBytes(enc.Encrypted(cipherBytes), iv: iv);
          return _isErrorResponse(Uint8List.fromList(decrypted));
        } catch (_) {}
      }
    } catch (_) {}
    return false;
  }

  /// Persists a local file to persistent app storage so it survives OS cache purges (e.g. iOS /tmp cleanup).
  Future<String> saveToPersistentStorage({
    required String originalPath,
    required String fileName,
    Uint8List? bytes,
  }) async {
    if (kIsWeb) return originalPath;
    try {
      final secureDir = await _getSecureStorageDir();
      var cleanName = fileName.replaceAll(RegExp(r'[^\w\.\-]'), '_');
      if (cleanName.isEmpty) cleanName = 'media_${DateTime.now().millisecondsSinceEpoch}';

      final ext = originalPath.contains('.') ? originalPath.split('.').last : '';
      if (ext.isNotEmpty && !cleanName.contains('.')) {
        cleanName = '$cleanName.$ext';
      }

      final targetFile = File('${secureDir.path}/$cleanName');

      if (bytes != null && bytes.isNotEmpty) {
        await targetFile.writeAsBytes(bytes, flush: true);
        debugPrint('SecureAttachmentService: Saved persistent file -> ${targetFile.path}');
        return targetFile.path;
      }

      final sourceFile = File(originalPath.replaceAll('file://', ''));
      if (await sourceFile.exists()) {
        await sourceFile.copy(targetFile.path);
        debugPrint('SecureAttachmentService: Copied to persistent storage -> ${targetFile.path}');
        return targetFile.path;
      }
    } catch (e) {
      debugPrint('SecureAttachmentService.saveToPersistentStorage error: $e');
    }
    return originalPath;
  }

  /// Downloads file from [url], encrypts it with AES-256, and stores in app private storage.
  Future<File> downloadAndEncryptAttachment({
    required String url,
    required String fileName,
    String? fileIdentifier,
    void Function(int count, int total)? onProgress,
  }) async {
    if (kIsWeb) {
      downloadFile(url, fileName, onProgress: onProgress);
      return File(url);
    }

    final fullUrl = _resolveFullUrl(url);
    if (fullUrl.isEmpty) {
      throw Exception('Cannot download attachment: URL is empty or invalid local path');
    }
    final id = (fileIdentifier != null && fileIdentifier.isNotEmpty) ? fileIdentifier : fullUrl;
    final secureDir = await _getSecureStorageDir();
    final encFileName = _getEncryptedFileName(fileName, id);
    final targetFile = File('${secureDir.path}/$encFileName');

    if (await targetFile.exists() && await targetFile.length() > 16) {
      final isCorrupt = await _isCorruptEncryptedFile(targetFile);
      if (isCorrupt) {
        debugPrint('SecureAttachmentService: Cached encrypted file is corrupt, purging -> ${targetFile.path}');
        try {
          await targetFile.delete();
        } catch (_) {}
      } else {
        debugPrint('SecureAttachmentService: Encrypted attachment already cached -> ${targetFile.path}');
        if (onProgress != null) {
          onProgress(50, 100);
          await Future.delayed(const Duration(milliseconds: 150));
          onProgress(100, 100);
        }
        return targetFile;
      }
    }

    // Check legacy location
    if (Platform.isAndroid) {
      final legacyFile = File('/storage/emulated/0/Download/Schat/$encFileName');
      if (await legacyFile.exists() && await legacyFile.length() > 16) {
        final isCorrupt = await _isCorruptEncryptedFile(legacyFile);
        if (isCorrupt) {
          try {
            await legacyFile.delete();
          } catch (_) {}
        } else {
          debugPrint('SecureAttachmentService: Found in legacy storage -> ${legacyFile.path}');
          if (onProgress != null) onProgress(100, 100);
          return legacyFile;
        }
      }
    }

    Uint8List rawBytes;
    final bool isLocal = fullUrl.startsWith('file://') || File(fullUrl.replaceAll('file://', '')).existsSync();
    if (isLocal) {
      final localFile = File(fullUrl.replaceAll('file://', ''));
      rawBytes = await localFile.readAsBytes();
      if (onProgress != null) onProgress(rawBytes.length, rawBytes.length);
    } else {
      debugPrint('SecureAttachmentService: Downloading raw attachment from $fullUrl');
      try {
        final response = await _cleanDio.get<List<int>>(
          fullUrl,
          options: Options(responseType: ResponseType.bytes),
          onReceiveProgress: (received, total) {
            if (onProgress != null && total > 0) {
              onProgress(received, total);
            }
          },
        );
        if (response.data != null && response.data!.isNotEmpty) {
          rawBytes = Uint8List.fromList(response.data!);
        } else {
          throw Exception('Empty response data');
        }
      } catch (dioError) {
        debugPrint('SecureAttachmentService: Dio error ($dioError), trying HTTP fallback for $fullUrl');
        final httpResponse = await http.get(Uri.parse(fullUrl)).timeout(const Duration(seconds: 15));
        if (httpResponse.statusCode == 200 && httpResponse.bodyBytes.isNotEmpty) {
          rawBytes = httpResponse.bodyBytes;
          if (onProgress != null) onProgress(rawBytes.length, rawBytes.length);
        } else {
          throw Exception('Failed to download attachment: HTTP ${httpResponse.statusCode}');
        }
      }
    }

    // Validate that raw bytes are actual media and not an error HTML/XML response
    if (_isErrorResponse(rawBytes)) {
      throw Exception('Server returned an error response instead of media data');
    }

    // AES-256 CBC Encryption
    final key = _getEncryptionKey();
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encryptedData = encrypter.encryptBytes(rawBytes, iv: iv);

    // Save format: [16-byte IV] + [Ciphertext]
    final combinedBytes = BytesBuilder()
      ..add(iv.bytes)
      ..add(encryptedData.bytes);

    await targetFile.writeAsBytes(combinedBytes.toBytes(), flush: true);
    debugPrint('SecureAttachmentService: Encrypted and saved to storage -> ${targetFile.path}');
    try {
      if (getIt.isRegistered<ScreenProtectionService>()) {
        await getIt<ScreenProtectionService>().scanFile(targetFile.path);
      }
    } catch (_) {}
    return targetFile;
  }

  /// Temporarily decrypts an encrypted attachment file into the app's temporary folder.
  Future<File> decryptToTemporaryFile({
    required String encryptedFilePath,
    required String originalFileName,
  }) async {
    if (kIsWeb) {
      return File(encryptedFilePath);
    }

    final encFile = File(encryptedFilePath);
    if (!await encFile.exists()) {
      throw Exception('Encrypted file not found at $encryptedFilePath');
    }

    try {
      final allBytes = await encFile.readAsBytes();
      var safeName = originalFileName.replaceAll(RegExp(r'[^\w\.\-]'), '_');
      while (safeName.endsWith('.enc')) {
        safeName = safeName.substring(0, safeName.length - 4);
      }
      if (safeName.isEmpty) safeName = 'decrypted_attachment';
      final tempDir = await _getTempDir();
      final tempFile = File('${tempDir.path}/temp_${DateTime.now().millisecondsSinceEpoch}_$safeName');

      // 1. If file has less than 16 bytes, write clean temp file and return
      if (allBytes.length < 16) {
        await tempFile.writeAsBytes(allBytes, flush: true);
        return tempFile;
      }

      // 2. Check if file is already unencrypted plaintext
      if (_isPlaintextFile(allBytes, safeName)) {
        await tempFile.writeAsBytes(allBytes, flush: true);
        debugPrint('SecureAttachmentService: File is unencrypted plaintext, extracted as $safeName');
        return tempFile;
      }

      final ivBytes = allBytes.sublist(0, 16);
      final cipherBytes = allBytes.sublist(16);

      // 3. Try candidate keys (user+device, user-only, common key, guest fallbacks)
      final List<enc.Key> candidateKeys = _getAllCandidateKeys();

      Uint8List? decryptedBytes;
      for (final key in candidateKeys) {
        try {
          final iv = enc.IV(Uint8List.fromList(ivBytes));
          final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
          Uint8List cBytes = cipherBytes;
          if (cBytes.length % 16 != 0) {
            final trimLen = cBytes.length - (cBytes.length % 16);
            if (trimLen >= 16) {
              cBytes = cBytes.sublist(0, trimLen);
            }
          }
          final res = encrypter.decryptBytes(
            enc.Encrypted(Uint8List.fromList(cBytes)),
            iv: iv,
          );
          if (res.isNotEmpty) {
            decryptedBytes = Uint8List.fromList(res);
            break;
          }
        } catch (_) {}
      }

      if (decryptedBytes != null && decryptedBytes.isNotEmpty) {
        if (_isErrorResponse(decryptedBytes)) {
          debugPrint('SecureAttachmentService: Decrypted content is an error response (<Error/XML/JSON), purging corrupt cache ${encFile.path}');
          try {
            await encFile.delete();
          } catch (_) {}
          throw Exception('Cached file was a server error response and has been purged');
        }

        // If safeName has no extension, detect it from decrypted bytes
        if (!safeName.contains('.')) {
          final detected = detectExtensionFromBytes(decryptedBytes);
          if (detected.isNotEmpty) {
            safeName = '$safeName.$detected';
          }
        }
        final finalTempFile = File('${tempDir.path}/temp_${DateTime.now().millisecondsSinceEpoch}_$safeName');
        await finalTempFile.writeAsBytes(decryptedBytes, flush: true);
        debugPrint('SecureAttachmentService: Decrypted temporary file -> ${finalTempFile.path}');
        return finalTempFile;
      }

      // 4. If decryption failed or not encrypted with those keys, extract as clean file without .enc
      if (_isErrorResponse(allBytes)) {
        debugPrint('SecureAttachmentService: Raw content is an error response, purging corrupt cache ${encFile.path}');
        try {
          await encFile.delete();
        } catch (_) {}
        throw Exception('Cached file was a server error response and has been purged');
      }

      await tempFile.writeAsBytes(allBytes, flush: true);
      debugPrint('SecureAttachmentService: Extracted raw file with clean extension -> ${tempFile.path}');
      return tempFile;
    } catch (e) {
      debugPrint('SecureAttachmentService: Error decrypting to temporary file: $e');
      rethrow;
    }
  }

  /// Detect standard file extension from file magic bytes.
  static String detectExtensionFromBytes(Uint8List bytes) {
    if (bytes.length < 2) return '';
    // PDF: %PDF
    if (bytes.length >= 4 && bytes[0] == 0x25 && bytes[1] == 0x50 && bytes[2] == 0x44 && bytes[3] == 0x46) {
      return 'pdf';
    }
    // JPEG: 0xFF, 0xD8, 0xFF
    if (bytes.length >= 3 && bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return 'jpg';
    }
    // PNG: 0x89, 'PNG'
    if (bytes.length >= 4 && bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
      return 'png';
    }
    // GIF: 'GIF8'
    if (bytes.length >= 4 && bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x38) {
      return 'gif';
    }
    // WEBP: 'RIFF'...'WEBP'
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 &&
        bytes[8] == 0x57 && bytes[9] == 0x45 && bytes[10] == 0x42 && bytes[11] == 0x50) {
      return 'webp';
    }
    // BMP: 'BM'
    if (bytes.length >= 2 && bytes[0] == 0x42 && bytes[1] == 0x4D) {
      return 'bmp';
    }
    // MP4 / M4A / MOV / HEIC: ftyp box at byte 4
    if (bytes.length >= 8 &&
        bytes[4] == 0x66 && bytes[5] == 0x74 && bytes[6] == 0x79 && bytes[7] == 0x70) {
      if (bytes.length >= 12) {
        final sub = String.fromCharCodes(bytes.sublist(8, 12)).toLowerCase();
        if (sub.contains('m4a')) return 'm4a';
        if (sub.contains('qt')) return 'mov';
        if (sub.contains('heic') || sub.contains('heix') || sub.contains('mif1') || sub.contains('msf1')) return 'heic';
        if (sub.contains('avif')) return 'avif';
      }
      return 'mp4';
    }
    // MP3: ID3 header ('ID3') or sync word
    if (bytes.length >= 3 && bytes[0] == 0x49 && bytes[1] == 0x44 && bytes[2] == 0x33) return 'mp3';
    if (bytes.length >= 2 && bytes[0] == 0xFF && (bytes[1] & 0xE0) == 0xE0) return 'mp3';
    // AMR: '#!AMR'
    if (bytes.length >= 5 && bytes[0] == 0x23 && bytes[1] == 0x21 && bytes[2] == 0x41 && bytes[3] == 0x4D && bytes[4] == 0x52) {
      return 'amr';
    }
    // FLAC: 'fLaC'
    if (bytes.length >= 4 && bytes[0] == 0x66 && bytes[1] == 0x4C && bytes[2] == 0x61 && bytes[3] == 0x43) {
      return 'flac';
    }
    // OGG: 'OggS'
    if (bytes.length >= 4 && bytes[0] == 0x4F && bytes[1] == 0x67 && bytes[2] == 0x67 && bytes[3] == 0x53) {
      return 'ogg';
    }
    // WAV: 'RIFF' .... 'WAVE'
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 &&
        bytes[8] == 0x57 && bytes[9] == 0x41 && bytes[10] == 0x56 && bytes[11] == 0x45) {
      return 'wav';
    }
    // ZIP / Office docx, xlsx, pptx: PK\x03\x04
    if (bytes.length >= 4 && bytes[0] == 0x50 && bytes[1] == 0x4B && bytes[2] == 0x03 && bytes[3] == 0x04) {
      return 'zip';
    }
    // Legacy Office DOC / XLS / PPT (OLE2 Compound Document)
    if (bytes.length >= 8 &&
        bytes[0] == 0xD0 && bytes[1] == 0xCF && bytes[2] == 0x11 && bytes[3] == 0xE0 &&
        bytes[4] == 0xA1 && bytes[5] == 0xB1 && bytes[6] == 0x1A && bytes[7] == 0xE1) {
      return 'doc';
    }
    // Matroska / WebM: 0x1A 0x45 0xDF 0xA3
    if (bytes.length >= 4 && bytes[0] == 0x1A && bytes[1] == 0x45 && bytes[2] == 0xDF && bytes[3] == 0xA3) {
      return 'webm';
    }
    return '';
  }

  /// Get standard MIME type based on file extension.
  static String getMimeTypeForExtension(String ext) {
    switch (ext.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'svg':
        return 'image/svg+xml';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'webm':
        return 'video/webm';
      case 'mkv':
        return 'video/x-matroska';
      case 'avi':
        return 'video/x-msvideo';
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'm4a':
        return 'audio/mp4';
      case 'aac':
        return 'audio/aac';
      case 'ogg':
      case 'opus':
        return 'audio/ogg';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'zip':
        return 'application/zip';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }

  /// Get standard media category based on file extension.
  static String getMediaTypeForExtension(String ext) {
    final lower = ext.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'svg', 'heic', 'bmp'].contains(lower)) {
      return 'image';
    }
    if (['mp4', 'mov', 'webm', 'mkv', 'avi', '3gp', 'flv', 'm4v'].contains(lower)) {
      return 'video';
    }
    if (['mp3', 'wav', 'm4a', 'aac', 'ogg', 'opus', 'flac', 'amr', 'wma'].contains(lower)) {
      return 'audio';
    }
    if (lower == 'pdf') {
      return 'pdf';
    }
    return 'file';
  }

  /// Get backend media_type identifier based on file extension.
  static String getBackendMediaTypeForExtension(String ext) {
    final mediaType = getMediaTypeForExtension(ext);
    switch (mediaType) {
      case 'image':
        return 'CHAT_IMAGE';
      case 'video':
        return 'CHAT_VIDEO';
      case 'audio':
        return 'CHAT_AUDIO';
      default:
        return 'DOCUMENT';
    }
  }

  /// Prepares an attachment for uploading and sending. If the file is in .enc format or encrypted,
  /// this method removes the encryption, cleans the file extension, writes the normal unencrypted
  /// bytes to a temporary upload file, and returns normal MIME and media types.
  Future<DecryptedAttachmentInfo> prepareNormalFileForUpload({
    String? filePath,
    Uint8List? fileBytes,
    required String fileName,
    String? explicitMediaType,
  }) async {
    // 1. Clean the filename by stripping directory path and any trailing .enc
    var cleanName = fileName.split('/').last.split('\\').last;
    while (cleanName.toLowerCase().endsWith('.enc')) {
      cleanName = cleanName.substring(0, cleanName.length - 4);
    }
    if (cleanName.isEmpty) cleanName = 'attachment';

    // 2. Read raw bytes
    Uint8List rawBytes;
    if (fileBytes != null && fileBytes.isNotEmpty) {
      rawBytes = fileBytes;
    } else if (filePath != null && filePath.isNotEmpty && !kIsWeb) {
      final f = File(filePath);
      if (await f.exists()) {
        rawBytes = await f.readAsBytes();
      } else {
        throw Exception('File not found at $filePath');
      }
    } else {
      rawBytes = Uint8List(0);
    }

    if (kIsWeb) {
      final ext = cleanName.contains('.') ? cleanName.split('.').last.toLowerCase() : '';
      return DecryptedAttachmentInfo(
        filePath: filePath ?? '',
        bytes: rawBytes,
        fileName: cleanName,
        mimeType: getMimeTypeForExtension(ext),
        mediaType: explicitMediaType ?? getMediaTypeForExtension(ext),
        backendMediaType: (explicitMediaType == 'VOICE_NOTE' || explicitMediaType == 'CHAT_AUDIO')
            ? explicitMediaType!
            : getBackendMediaTypeForExtension(ext),
        fileSizeBytes: rawBytes.length,
      );
    }

    // 3. Decrypt bytes if encrypted
    Uint8List normalBytes = rawBytes;
    if (rawBytes.length >= 16) {
      final bool isPlain = _isPlaintextFile(rawBytes, cleanName);
      if (!isPlain) {
        final ivBytes = rawBytes.sublist(0, 16);
        final cipherBytes = rawBytes.sublist(16);

        if (cipherBytes.isNotEmpty) {
          final List<enc.Key> candidateKeys = _getAllCandidateKeys();

          for (final key in candidateKeys) {
            try {
              final iv = enc.IV(Uint8List.fromList(ivBytes));
              final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
              Uint8List cBytes = cipherBytes;
              if (cBytes.length % 16 != 0) {
                final trimLen = cBytes.length - (cBytes.length % 16);
                if (trimLen >= 16) {
                  cBytes = cBytes.sublist(0, trimLen);
                }
              }
              final res = encrypter.decryptBytes(
                enc.Encrypted(Uint8List.fromList(cBytes)),
                iv: iv,
              );
              if (res.isNotEmpty && !_isErrorResponse(Uint8List.fromList(res))) {
                normalBytes = Uint8List.fromList(res);
                debugPrint('SecureAttachmentService: Successfully decrypted .enc file "$fileName" -> ${normalBytes.length} bytes');
                break;
              }
            } catch (_) {}
          }
        }
      }
    }

    // 4. Resolve extension from magic bytes if missing or generic
    String currentExt = '';
    if (cleanName.contains('.')) {
      currentExt = cleanName.split('.').last.toLowerCase();
    }
    final detectedExt = detectExtensionFromBytes(normalBytes);
    if (currentExt.isEmpty || currentExt == 'enc' || currentExt == 'bin' || currentExt == 'tmp') {
      if (detectedExt.isNotEmpty) {
        final baseName = cleanName.contains('.')
            ? cleanName.substring(0, cleanName.lastIndexOf('.'))
            : cleanName;
        cleanName = '$baseName.$detectedExt';
        currentExt = detectedExt;
      }
    }

    // 5. Determine types
    final resolvedExt = currentExt.isNotEmpty ? currentExt : detectedExt;
    final mimeType = getMimeTypeForExtension(resolvedExt);
    final mediaType = (explicitMediaType != null && explicitMediaType != 'file')
        ? explicitMediaType
        : getMediaTypeForExtension(resolvedExt);
    final backendMediaType = (explicitMediaType == 'VOICE_NOTE' || explicitMediaType == 'CHAT_AUDIO')
        ? explicitMediaType!
        : getBackendMediaTypeForExtension(resolvedExt);

    // 6. Write normal unencrypted bytes to a clean temporary file
    final tempDir = await _getTempDir();
    final cleanFile = File('${tempDir.path}/schat_upload_${DateTime.now().millisecondsSinceEpoch}_$cleanName');
    await cleanFile.writeAsBytes(normalBytes, flush: true);

    // 7. Also save to persistent storage so sender can immediately view locally
    try {
      await saveToPersistentStorage(
        originalPath: cleanFile.path,
        fileName: cleanName,
        bytes: normalBytes,
      );
    } catch (_) {}

    debugPrint('SecureAttachmentService: Upload file ready: "${cleanFile.path}", name: "$cleanName", mime: "$mimeType", type: "$mediaType"');

    return DecryptedAttachmentInfo(
      filePath: cleanFile.path,
      bytes: normalBytes,
      fileName: cleanName,
      mimeType: mimeType,
      mediaType: mediaType,
      backendMediaType: backendMediaType,
      fileSizeBytes: normalBytes.length,
    );
  }

  /// Securely downloads (if needed), encrypts, and then decrypts an attachment into a temporary file.
  Future<File> getDecryptedTempFileForViewing({
    required String url,
    required String fileName,
    String? fileIdentifier,
  }) async {
    if (kIsWeb) {
      return File(_resolveFullUrl(url));
    }

    final encFile = await downloadAndEncryptAttachment(
      url: url,
      fileName: fileName,
      fileIdentifier: fileIdentifier,
    );

    return await decryptToTemporaryFile(
      encryptedFilePath: encFile.path,
      originalFileName: fileName,
    );
  }

  /// Deletes a temporary decrypted file immediately after viewer is closed.
  /// Strictly ensures that ONLY files inside the app's temporary cache directory are deleted,
  /// never deleting user storage files (such as in Download/Schat/).
  Future<void> cleanupTempFile(File? tempFile) async {
    if (kIsWeb || tempFile == null) return;
    try {
      final tempDir = await _getTempDir();
      final tempDirPath = tempDir.path;
      // Safety guard: only delete if the file is inside the temporary decrypted cache directory
      if (!tempFile.path.startsWith(tempDirPath)) {
        debugPrint('SecureAttachmentService: Skip cleanup of non-temporary file -> ${tempFile.path}');
        return;
      }
      if (await tempFile.exists()) {
        await tempFile.delete();
        debugPrint('SecureAttachmentService: Cleaned up temporary decrypted file -> ${tempFile.path}');
      }
    } catch (e) {
      debugPrint('SecureAttachmentService: Error cleaning temp file: $e');
    }
  }

  /// Deletes all encrypted attachments and temporary files on user logout.
  Future<void> clearAllEncryptedData() async {
    if (kIsWeb) return;
    try {
      final secureDir = await _getSecureStorageDir();
      if (await secureDir.exists()) {
        await secureDir.delete(recursive: true);
        debugPrint('SecureAttachmentService: Wiped all encrypted attachments');
      }
      final tempDir = await _getTempDir();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
        debugPrint('SecureAttachmentService: Wiped all temporary decrypted attachment files');
      }
    } catch (e) {
      debugPrint('SecureAttachmentService: Error during logout data wipe: $e');
    }
  }
}

/// Metadata and resolved paths for a normalized, decrypted attachment ready for upload/send.
class DecryptedAttachmentInfo {
  final String filePath;
  final Uint8List bytes;
  final String fileName;
  final String mimeType;
  final String mediaType;
  final String backendMediaType;
  final int fileSizeBytes;

  const DecryptedAttachmentInfo({
    required this.filePath,
    required this.bytes,
    required this.fileName,
    required this.mimeType,
    required this.mediaType,
    required this.backendMediaType,
    required this.fileSizeBytes,
  });
}
