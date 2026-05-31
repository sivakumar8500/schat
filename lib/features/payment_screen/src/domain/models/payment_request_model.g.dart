// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PaymentRequestModel _$PaymentRequestModelFromJson(Map<String, dynamic> json) =>
    _PaymentRequestModel(
      planId: json['planId'] as String,
      cardholderName: json['cardholderName'] as String,
      cardNumber: json['cardNumber'] as String,
      expiry: json['expiry'] as String,
      cvv: json['cvv'] as String,
    );

Map<String, dynamic> _$PaymentRequestModelToJson(
  _PaymentRequestModel instance,
) => <String, dynamic>{
  'planId': instance.planId,
  'cardholderName': instance.cardholderName,
  'cardNumber': instance.cardNumber,
  'expiry': instance.expiry,
  'cvv': instance.cvv,
};
