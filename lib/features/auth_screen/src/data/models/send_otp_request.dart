import 'package:freezed_annotation/freezed_annotation.dart';

part 'send_otp_request.freezed.dart';
part 'send_otp_request.g.dart';

@freezed
abstract class SendOtpRequest with _$SendOtpRequest {
  const factory SendOtpRequest({
    @JsonKey(name: 'phone_number') required String phoneNumber,
  }) = _SendOtpRequest;

  factory SendOtpRequest.fromJson(Map<String, dynamic> json) => _$SendOtpRequestFromJson(json);
}
