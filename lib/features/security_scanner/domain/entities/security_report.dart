import 'package:freezed_annotation/freezed_annotation.dart';

part 'security_report.freezed.dart';

@freezed
abstract class SecurityReport with _$SecurityReport {
  const factory SecurityReport({
    required bool isSafe,
    required String riskLevel,
    required String message,
  }) = _SecurityReport;
}
