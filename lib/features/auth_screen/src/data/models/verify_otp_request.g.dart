// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verify_otp_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_VerifyOtpRequest _$VerifyOtpRequestFromJson(Map<String, dynamic> json) =>
    _VerifyOtpRequest(
      phoneNumber: json['phone_number'] as String,
      otp: json['otp'] as String,
      deviceId: json['device_id'] as String,
    );

Map<String, dynamic> _$VerifyOtpRequestToJson(_VerifyOtpRequest instance) =>
    <String, dynamic>{
      'phone_number': instance.phoneNumber,
      'otp': instance.otp,
      'device_id': instance.deviceId,
    };
