import 'package:freezed_annotation/freezed_annotation.dart';

part 'create_scheduled_message_request.freezed.dart';
part 'create_scheduled_message_request.g.dart';

@freezed
abstract class CreateScheduledMessageRequest with _$CreateScheduledMessageRequest {
  const factory CreateScheduledMessageRequest({
    required String conversationId,
    @Default('text') String messageType,
    String? parentMessageId,
    @Default({}) Map<String, dynamic> content,
    @Default({}) Map<String, dynamic> security,
    @Default({}) Map<String, dynamic> viewControl,
    @Default({}) Map<String, dynamic> expiry,
    Map<String, dynamic>? callMeta,
    required String scheduledAt,
  }) = _CreateScheduledMessageRequest;

  factory CreateScheduledMessageRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateScheduledMessageRequestFromJson(json);
}
