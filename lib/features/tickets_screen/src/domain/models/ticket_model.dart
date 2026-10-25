import 'package:freezed_annotation/freezed_annotation.dart';

part 'ticket_model.freezed.dart';
part 'ticket_model.g.dart';

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toInt();
  if (value is String) {
    final direct = int.tryParse(value);
    if (direct != null) return direct;
    final dt = DateTime.tryParse(value);
    if (dt != null) {
      return dt.millisecondsSinceEpoch ~/ 1000;
    }
    return null;
  }
  if (value is Map) {
    return _parseInt(value.values.first);
  }
  final str = value.toString();
  final direct = int.tryParse(str);
  if (direct != null) return direct;
  final dt = DateTime.tryParse(str);
  if (dt != null) {
    return dt.millisecondsSinceEpoch ~/ 1000;
  }
  return null;
}

Object? _readAttachmentPath(Map json, String key) {
  return json['attachmentPath'] ?? json['attachment_path'] ?? json['imageUrl'] ?? json['image_url'];
}

@freezed
abstract class TicketModel with _$TicketModel {
  const factory TicketModel({
    required String id,
    required String title,
    required String description,
    @JsonKey(name: 'attachmentPath', readValue: _readAttachmentPath) String? attachmentPath,
    required String status,
    @JsonKey(name: 'createdAt', fromJson: _parseInt) int? createdAtInt,
  }) = _TicketModel;

  factory TicketModel.fromJson(Map<String, dynamic> json) => _$TicketModelFromJson(json);
}
