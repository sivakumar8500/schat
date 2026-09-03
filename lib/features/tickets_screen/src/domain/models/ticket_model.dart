import 'package:freezed_annotation/freezed_annotation.dart';

part 'ticket_model.freezed.dart';
part 'ticket_model.g.dart';

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  if (value is Map) {
    return int.tryParse(value.values.first?.toString() ?? '');
  }
  return int.tryParse(value.toString());
}

@freezed
abstract class TicketModel with _$TicketModel {
  const factory TicketModel({
    required String id,
    required String title,
    required String description,
    String? attachmentPath,
    required String status,
    @JsonKey(name: 'createdAt', fromJson: _parseInt) int? createdAtInt,
  }) = _TicketModel;

  factory TicketModel.fromJson(Map<String, dynamic> json) => _$TicketModelFromJson(json);
}
