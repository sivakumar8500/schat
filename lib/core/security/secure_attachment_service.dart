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
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 60),
          followRedirects: true,
          maxRedirects: 5,
          validateStatus: (status) => status != null && status < 500,
        ));

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

    String s3BaseUrl;
    try {
      final serverUri = Uri.parse(CommonEndpoints.baseUrl);
      var host = serverUri.host;
      if (!kIsWeb && Platform.isAndroid && (host == 'localhost' || host == '127.0.0.1' || host.isEmpty)) {
        host = '10.0.2.2';
      }
      final scheme = serverUri.scheme.isNotEmpty ? serverUri.scheme : 'http';
      if (host.isNotEmpty && host != 'qlyncs.com' && !host.contains('amazonaws.com')) {
        s3BaseUrl = '$scheme://$host:9000/qlyncs-doc/';
      } else {
        s3BaseUrl = 'https://qlyncs-doc.s3.amazonaws.com/';
      }
    } catch (_) {
      s3BaseUrl = 'https://qlyncs-doc.s3.amazonaws.com/';
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

  bool _isPlaintextFile(Uint8List bytes, String safeName) {
    if (bytes.length < 4) return false;
    final lower = safeName.toLowerCase();

    // MP3: ID3 header ('ID3') or sync word (0xFFE0 mask)
    if (lower.endsWith('.mp3')) {
      if (bytes[0] == 0x49 && bytes[1] == 0x44 && bytes[2] == 0x33) return true; // 'ID3'
      if (bytes[0] == 0xFF && (bytes[1] & 0xE0) == 0xE0) return true; // MPEG frame sync
    }

    // WAV: 'RIFF' .... 'WAVE'
    if (lower.endsWith('.wav')) {
      if (bytes.length >= 12 &&
          bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 &&
          bytes[8] == 0x57 && bytes[9] == 0x41 && bytes[10] == 0x56 && bytes[11] == 0x45) {
        return true;
      }
    }

    // MP4 / M4A / MOV: ftyp box at byte 4
    if (lower.endsWith('.mp4') || lower.endsWith('.m4a') || lower.endsWith('.mov')) {
      if (bytes.length >= 8 &&
          bytes[4] == 0x66 && bytes[5] == 0x74 && bytes[6] == 0x79 && bytes[7] == 0x70) {
        return true; // 'ftyp'
      }
    }

    // JPEG
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) return true;
    }

    // PNG
    if (lower.endsWith('.png')) {
      if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) return true;
    }

    // PDF
    if (lower.endsWith('.pdf')) {
      if (bytes[0] == 0x25 && bytes[1] == 0x50 && bytes[2] == 0x44 && bytes[3] == 0x46) return true; // '%PDF'
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

  Future<bool> isAttachmentCached(String identifier) async {
    if (kIsWeb) return false;
    try {
      final secureDir = await _getSecureStorageDir();
      final encFileName = _getEncryptedFileName('File', identifier);
      final rawWithoutEnc = encFileName.endsWith('.enc')
          ? encFileName.substring(0, encFileName.length - 4)
          : encFileName;
      final file1 = File('${secureDir.path}/$encFileName');
      final file2 = File('${secureDir.path}/$rawWithoutEnc');
      return await file1.exists() || await file2.exists();
    } catch (_) {
      return false;
    }
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
    final id = (fileIdentifier != null && fileIdentifier.isNotEmpty) ? fileIdentifier : fullUrl;
    final secureDir = await _getSecureStorageDir();
    final encFileName = _getEncryptedFileName(fileName, id);
    final targetFile = File('${secureDir.path}/$encFileName');

    if (await targetFile.exists()) {
      debugPrint('SecureAttachmentService: Encrypted attachment already cached -> ${targetFile.path}');
      if (onProgress != null) {
        onProgress(50, 100);
        await Future.delayed(const Duration(milliseconds: 150));
        onProgress(100, 100);
      }
      return targetFile;
    }

    // Check legacy location
    if (Platform.isAndroid) {
      final legacyFile = File('/storage/emulated/0/Download/Schat/$encFileName');
      if (await legacyFile.exists()) {
        debugPrint('SecureAttachmentService: Found in legacy storage -> ${legacyFile.path}');
        if (onProgress != null) onProgress(100, 100);
        return legacyFile;
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
        final httpResponse = await http.get(Uri.parse(fullUrl));
        if (httpResponse.statusCode == 200 && httpResponse.bodyBytes.isNotEmpty) {
          rawBytes = httpResponse.bodyBytes;
          if (onProgress != null) onProgress(rawBytes.length, rawBytes.length);
        } else {
          throw Exception('Failed to download attachment: HTTP ${httpResponse.statusCode}');
        }
      }
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

      // 3. Try candidate keys (user+device, user-only, common key)
      final List<enc.Key> candidateKeys = [
        _getEncryptionKey(),
        _getFallbackKeyUserOnly(),
        _getFallbackKeyCommon(),
      ];

      Uint8List? decryptedBytes;
      for (final key in candidateKeys) {
        try {
          final iv = enc.IV(Uint8List.fromList(ivBytes));
          final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
          final res = encrypter.decryptBytes(
            enc.Encrypted(Uint8List.fromList(cipherBytes)),
            iv: iv,
          );
          if (res.isNotEmpty) {
            decryptedBytes = Uint8List.fromList(res);
            break;
          }
        } catch (_) {}
      }

      if (decryptedBytes != null && decryptedBytes.isNotEmpty) {
        await tempFile.writeAsBytes(decryptedBytes, flush: true);
        debugPrint('SecureAttachmentService: Decrypted temporary file -> ${tempFile.path}');
        return tempFile;
      }

      // 4. If decryption failed or not encrypted with those keys, extract as clean file without .enc
      await tempFile.writeAsBytes(allBytes, flush: true);
      debugPrint('SecureAttachmentService: Extracted raw file with clean extension -> ${tempFile.path}');
      return tempFile;
    } catch (e) {
      debugPrint('SecureAttachmentService: Error decrypting to temporary file: $e');
      return encFile;
    }
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
  Future<void> cleanupTempFile(File? tempFile) async {
    if (kIsWeb || tempFile == null) return;
    try {
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
