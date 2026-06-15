import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_socket_model.freezed.dart';
part 'chat_socket_model.g.dart';

@freezed
abstract class ChatSocketModel with _$ChatSocketModel {
  const factory ChatSocketModel({
    required String id,
  }) = _ChatSocketModel;

  factory ChatSocketModel.fromJson(Map<String, dynamic> json) => _$ChatSocketModelFromJson(json);
}
