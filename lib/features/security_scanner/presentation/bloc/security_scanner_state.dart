import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/security_report.dart';

part 'security_scanner_state.freezed.dart';

@freezed
class SecurityScannerState with _$SecurityScannerState {
  const factory SecurityScannerState.initial() = _Initial;
  const factory SecurityScannerState.loading() = _Loading;
  const factory SecurityScannerState.integrityResult(bool isSafe) = _IntegrityResult;
  const factory SecurityScannerState.scanResult(SecurityReport report) = _ScanResult;
  const factory SecurityScannerState.error(String message) = _Error;
}
