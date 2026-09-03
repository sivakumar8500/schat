// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'emergency_contact_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EmergencyContactResponse _$EmergencyContactResponseFromJson(
  Map<String, dynamic> json,
) => _EmergencyContactResponse(
  personalContacts:
      (json['personalContacts'] as List<dynamic>?)
          ?.map((e) => PersonalContact.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  defaultContacts:
      (json['defaultContacts'] as List<dynamic>?)
          ?.map((e) => DefaultContact.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$EmergencyContactResponseToJson(
  _EmergencyContactResponse instance,
) => <String, dynamic>{
  'personalContacts': instance.personalContacts,
  'defaultContacts': instance.defaultContacts,
};

_PersonalContact _$PersonalContactFromJson(Map<String, dynamic> json) =>
    _PersonalContact(
      id: json['id'] as String,
      phoneNumber: json['phoneNumber'] as String,
      contactName: json['contactName'] as String,
      createdAtInt: _parseInt(json['createdAt']),
    );

Map<String, dynamic> _$PersonalContactToJson(_PersonalContact instance) =>
    <String, dynamic>{
      'id': instance.id,
      'phoneNumber': instance.phoneNumber,
      'contactName': instance.contactName,
      'createdAt': instance.createdAtInt,
    };

_DefaultContact _$DefaultContactFromJson(Map<String, dynamic> json) =>
    _DefaultContact(
      id: json['id'] as String,
      name: json['name'] as String,
      phoneNumber: json['phoneNumber'] as String,
      description: json['description'] as String,
      createdAtInt: _parseInt(json['createdAt']),
      updatedAtInt: _parseInt(json['updatedAt']),
    );

Map<String, dynamic> _$DefaultContactToJson(_DefaultContact instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'phoneNumber': instance.phoneNumber,
      'description': instance.description,
      'createdAt': instance.createdAtInt,
      'updatedAt': instance.updatedAtInt,
    };
