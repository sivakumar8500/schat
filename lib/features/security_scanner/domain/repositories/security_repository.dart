import '../entities/security_report.dart';

abstract class SecurityRepository {
  Future<bool> checkDeviceIntegrity();
  Future<SecurityReport> scanUrl(String url);
  Future<SecurityReport> scanFile(String filePath);
}
