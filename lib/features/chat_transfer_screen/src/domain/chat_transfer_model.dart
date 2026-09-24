import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_transfer_model.freezed.dart';
part 'chat_transfer_model.g.dart';

@freezed
abstract class ChatTransferModel with _$ChatTransferModel {
  const factory ChatTransferModel({
    required String id,
  }) = _ChatTransferModel;

  factory ChatTransferModel.fromJson(Map<String, dynamic> json) => _$ChatTransferModelFromJson(json);
}
