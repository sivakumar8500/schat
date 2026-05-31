import 'package:freezed_annotation/freezed_annotation.dart';

part 'payment_request_model.freezed.dart';
part 'payment_request_model.g.dart';

@freezed
abstract class PaymentRequestModel with _$PaymentRequestModel {
  const factory PaymentRequestModel({
    required String planId,
    required String cardholderName,
    required String cardNumber,
    required String expiry,
    required String cvv,
  }) = _PaymentRequestModel;

  factory PaymentRequestModel.fromJson(Map<String, dynamic> json) => _$PaymentRequestModelFromJson(json);
}
