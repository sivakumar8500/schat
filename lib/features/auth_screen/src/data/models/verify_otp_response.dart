import 'package:freezed_annotation/freezed_annotation.dart';

part 'verify_otp_response.freezed.dart';
part 'verify_otp_response.g.dart';

@freezed
abstract class VerifyOtpResponse with _$VerifyOtpResponse {
  const factory VerifyOtpResponse({
    @JsonKey(name: 'access_token') required String accessToken,
    @JsonKey(name: 'refresh_token') required String refreshToken,
    @JsonKey(name: 'token_type') required String tokenType,
  }) = _VerifyOtpResponse;

  factory VerifyOtpResponse.fromJson(Map<String, dynamic> json) => _$VerifyOtpResponseFromJson(json);
}
