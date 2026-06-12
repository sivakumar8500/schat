import 'package:freezed_annotation/freezed_annotation.dart';

part 'verify_otp_request.freezed.dart';
part 'verify_otp_request.g.dart';

@freezed
abstract class VerifyOtpRequest with _$VerifyOtpRequest {
  const factory VerifyOtpRequest({
    @JsonKey(name: 'phone_number') required String phoneNumber,
    required String otp,
    @JsonKey(name: 'device_id') required String deviceId,
  }) = _VerifyOtpRequest;

  factory VerifyOtpRequest.fromJson(Map<String, dynamic> json) => _$VerifyOtpRequestFromJson(json);
}
