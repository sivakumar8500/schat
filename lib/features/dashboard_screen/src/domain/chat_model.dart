import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_model.freezed.dart';
part 'chat_model.g.dart';

@freezed
abstract class ChatModel with _$ChatModel {
  const factory ChatModel({
    required String id,
    @JsonKey(name: 'is_group') required bool isGroup,
    @JsonKey(name: 'group_name') String? groupName,
    @JsonKey(name: 'group_description') String? groupDescription,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'updated_at') required String updatedAt,
  }) = _ChatModel;

  factory ChatModel.fromJson(Map<String, dynamic> json) => _$ChatModelFromJson(json);
}
