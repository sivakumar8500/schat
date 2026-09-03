import 'package:freezed_annotation/freezed_annotation.dart';

part 'emergency_contact_response.freezed.dart';
part 'emergency_contact_response.g.dart';

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
abstract class EmergencyContactResponse with _$EmergencyContactResponse {
  const factory EmergencyContactResponse({
    @Default([]) List<PersonalContact> personalContacts,
    @Default([]) List<DefaultContact> defaultContacts,
  }) = _EmergencyContactResponse;

  factory EmergencyContactResponse.fromJson(Map<String, dynamic> json) =>
      _$EmergencyContactResponseFromJson(json);
}

@freezed
abstract class PersonalContact with _$PersonalContact {
  const factory PersonalContact({
    required String id,
    required String phoneNumber,
    required String contactName,
    @JsonKey(name: 'createdAt', fromJson: _parseInt) int? createdAtInt,
  }) = _PersonalContact;

  factory PersonalContact.fromJson(Map<String, dynamic> json) =>
      _$PersonalContactFromJson(json);
}

@freezed
abstract class DefaultContact with _$DefaultContact {
  const factory DefaultContact({
    required String id,
    required String name,
    required String phoneNumber,
    required String description,
    @JsonKey(name: 'createdAt', fromJson: _parseInt) int? createdAtInt,
    @JsonKey(name: 'updatedAt', fromJson: _parseInt) int? updatedAtInt,
  }) = _DefaultContact;

  factory DefaultContact.fromJson(Map<String, dynamic> json) =>
      _$DefaultContactFromJson(json);
}
