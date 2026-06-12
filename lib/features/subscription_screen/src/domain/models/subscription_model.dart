import 'package:freezed_annotation/freezed_annotation.dart';

part 'subscription_model.freezed.dart';
part 'subscription_model.g.dart';

@freezed
abstract class SubscriptionModel with _$SubscriptionModel {
  const factory SubscriptionModel({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'plan_id') required String planId,
    required String status,
    @JsonKey(name: 'start_date') required String startDate,
    @JsonKey(name: 'end_date') required String endDate,
  }) = _SubscriptionModel;

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) => _$SubscriptionModelFromJson(json);
}
