import 'package:freezed_annotation/freezed_annotation.dart';

part 'security_scanner_event.freezed.dart';

@freezed
class SecurityScannerEvent with _$SecurityScannerEvent {
  const factory SecurityScannerEvent.checkIntegrity() = CheckIntegrity;
  const factory SecurityScannerEvent.scanUrl(String url) = ScanUrl;
  const factory SecurityScannerEvent.scanFile(String filePath) = ScanFile;
}
