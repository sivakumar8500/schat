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
import 'package:schat/utils/common_endpoints.dart';
import 'package:schat/utils/download_helper/download_helper.dart';

@lazySingleton
class SecureAttachmentService {
  final StorageService _storageService;
  final Dio _dio;
  final Dio _cleanDio;

  SecureAttachmentService(this._storageService, Dio? dio)
      : _dio = dio ?? Dio(),
        _cleanDio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 60),
          followRedirects: true,
          maxRedirects: 5,
          validateStatus: (status) => status != null && status < 500,
        ));

  /// Resolve relative paths into full S3 or MinIO URLs.
  String _resolveFullUrl(String path) {
    final cleanPath = path.replaceAll('file://', '');
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
      if (host == '13.201.205.176' || host == '10.0.2.2' || host == 'localhost') {
        s3BaseUrl = 'http://$host:9000/qlyncs-docs/';
      } else {
        s3BaseUrl = 'https://qlyncs-docs.s3.ap-south-1.amazonaws.com/';
      }
    } catch (_) {
      s3BaseUrl = 'https://qlyncs-docs.s3.ap-south-1.amazonaws.com/';
    }
    return '$s3BaseUrl$path';
  }

  /// Derive 256-bit (32-byte) AES key based on user and device identity.
  enc.Key _getEncryptionKey() {
    final userId = _storageService.getUserId() ?? 'guest_user';
    final deviceId = _storageService.getOrGenerateDeviceId();
    final rawSeed = 'schat_sec_attachment_${userId}_$deviceId';
    final keyBytes = sha256.convert(utf8.encode(rawSeed)).bytes;
    return enc.Key(Uint8List.fromList(keyBytes));
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
      if (onProgress != null) onProgress(100, 100);
      return targetFile;
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
    debugPrint('SecureAttachmentService: Encrypted and saved to private storage -> ${targetFile.path}');
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
      if (allBytes.length < 16) {
        return encFile;
      }

      final ivBytes = allBytes.sublist(0, 16);
      final cipherBytes = allBytes.sublist(16);

      final key = _getEncryptionKey();
      final iv = enc.IV(Uint8List.fromList(ivBytes));
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));

      final decryptedBytes = encrypter.decryptBytes(
        enc.Encrypted(Uint8List.fromList(cipherBytes)),
        iv: iv,
      );

      var safeName = originalFileName.replaceAll(RegExp(r'[^\w\.\-]'), '_');
      while (safeName.endsWith('.enc')) {
        safeName = safeName.substring(0, safeName.length - 4);
      }
      if (safeName.isEmpty) safeName = 'decrypted_attachment';
      final tempDir = await _getTempDir();
      final tempFile = File('${tempDir.path}/temp_${DateTime.now().millisecondsSinceEpoch}_$safeName');

      await tempFile.writeAsBytes(decryptedBytes, flush: true);
      debugPrint('SecureAttachmentService: Decrypted temporary file -> ${tempFile.path}');
      return tempFile;
    } catch (e) {
      debugPrint('SecureAttachmentService: File not AES encrypted by Schat key, returning raw file: $e');
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
