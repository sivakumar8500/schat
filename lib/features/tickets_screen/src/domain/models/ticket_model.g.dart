// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ticket_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TicketModel _$TicketModelFromJson(Map<String, dynamic> json) => _TicketModel(
  id: json['id'] as String,
  title: json['title'] as String,
  description: json['description'] as String,
  attachmentPath: json['attachmentPath'] as String?,
  status: json['status'] as String,
  createdAtInt: _parseInt(json['createdAt']),
);

Map<String, dynamic> _$TicketModelToJson(_TicketModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'attachmentPath': instance.attachmentPath,
      'status': instance.status,
      'createdAt': instance.createdAtInt,
    };
