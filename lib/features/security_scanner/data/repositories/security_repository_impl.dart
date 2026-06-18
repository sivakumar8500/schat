import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:injectable/injectable.dart';
import 'package:safe_device/safe_device.dart';
import '../../domain/entities/security_report.dart';
import '../../domain/repositories/security_repository.dart';

@LazySingleton(as: SecurityRepository)
class SecurityRepositoryImpl implements SecurityRepository {
  final List<String> _suspiciousKeywords = [
    '.exe',
    '.apk',
    '.bat',
    '.sh',
    'bit.ly',
    'verify-account',
  ];
  final List<String> _maliciousExtensions = [
    '.exe',
    '.apk',
    '.bat',
    '.sh',
    '.msi',
  ];

  @override
  Future<bool> checkDeviceIntegrity() async {
    bool isJailBroken = await SafeDevice.isJailBroken;
    // bool isRealDevice = await SafeDevice.isRealDevice;
    // For production, we usually want !isJailBroken && isRealDevice
    // But for this task, we return true if it's safe (not jail broken).
    return !isJailBroken;
  }

  @override
  Future<SecurityReport> scanUrl(String url) async {
    bool isSuspicious = _suspiciousKeywords.any(
      (keyword) => url.toLowerCase().contains(keyword),
    );

    if (isSuspicious) {
      return SecurityReport(
        isSafe: false,
        riskLevel: 'HIGH',
        message: 'Suspicious link detected. It might be a phishing attempt.',
      );
    }

    return const SecurityReport(
      isSafe: true,
      riskLevel: 'LOW',
      message: 'Link appears to be safe.',
    );
  }

  @override
  Future<SecurityReport> scanFile(String filePath) async {
    bool hasMaliciousExtension = _maliciousExtensions.any(
      (ext) => filePath.toLowerCase().endsWith(ext),
    );

    if (hasMaliciousExtension) {
      return SecurityReport(
        isSafe: false,
        riskLevel: 'CRITICAL',
        message: 'Malicious file extension detected ($filePath).',
      );
    }

    final file = File(filePath);
    if (!await file.exists()) {
      return const SecurityReport(
        isSafe: false,
        riskLevel: 'UNKNOWN',
        message: 'File not found.',
      );
    }

    try {
      final bytes = await file.readAsBytes();
      final hash = sha256.convert(bytes);
      // In a real app, we would check this hash against a database like VirusTotal.
      // For now, we just return safe if the extension is okay.
      return SecurityReport(
        isSafe: true,
        riskLevel: 'LOW',
        message:
            'File hash: ${hash.toString().substring(0, 8)}... appears safe.',
      );
    } catch (e) {
      return SecurityReport(
        isSafe: false,
        riskLevel: 'ERROR',
        message: 'Failed to scan file: $e',
      );
    }
  }
}
