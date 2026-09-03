// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'emergency_contact_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EmergencyContactResponse {

 List<PersonalContact> get personalContacts; List<DefaultContact> get defaultContacts;
/// Create a copy of EmergencyContactResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EmergencyContactResponseCopyWith<EmergencyContactResponse> get copyWith => _$EmergencyContactResponseCopyWithImpl<EmergencyContactResponse>(this as EmergencyContactResponse, _$identity);

  /// Serializes this EmergencyContactResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EmergencyContactResponse&&const DeepCollectionEquality().equals(other.personalContacts, personalContacts)&&const DeepCollectionEquality().equals(other.defaultContacts, defaultContacts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(personalContacts),const DeepCollectionEquality().hash(defaultContacts));

@override
String toString() {
  return 'EmergencyContactResponse(personalContacts: $personalContacts, defaultContacts: $defaultContacts)';
}


}

/// @nodoc
abstract mixin class $EmergencyContactResponseCopyWith<$Res>  {
  factory $EmergencyContactResponseCopyWith(EmergencyContactResponse value, $Res Function(EmergencyContactResponse) _then) = _$EmergencyContactResponseCopyWithImpl;
@useResult
$Res call({
 List<PersonalContact> personalContacts, List<DefaultContact> defaultContacts
});




}
/// @nodoc
class _$EmergencyContactResponseCopyWithImpl<$Res>
    implements $EmergencyContactResponseCopyWith<$Res> {
  _$EmergencyContactResponseCopyWithImpl(this._self, this._then);

  final EmergencyContactResponse _self;
  final $Res Function(EmergencyContactResponse) _then;

/// Create a copy of EmergencyContactResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? personalContacts = null,Object? defaultContacts = null,}) {
  return _then(_self.copyWith(
personalContacts: null == personalContacts ? _self.personalContacts : personalContacts // ignore: cast_nullable_to_non_nullable
as List<PersonalContact>,defaultContacts: null == defaultContacts ? _self.defaultContacts : defaultContacts // ignore: cast_nullable_to_non_nullable
as List<DefaultContact>,
  ));
}

}


/// Adds pattern-matching-related methods to [EmergencyContactResponse].
extension EmergencyContactResponsePatterns on EmergencyContactResponse {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EmergencyContactResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EmergencyContactResponse() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EmergencyContactResponse value)  $default,){
final _that = this;
switch (_that) {
case _EmergencyContactResponse():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EmergencyContactResponse value)?  $default,){
final _that = this;
switch (_that) {
case _EmergencyContactResponse() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<PersonalContact> personalContacts,  List<DefaultContact> defaultContacts)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EmergencyContactResponse() when $default != null:
return $default(_that.personalContacts,_that.defaultContacts);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<PersonalContact> personalContacts,  List<DefaultContact> defaultContacts)  $default,) {final _that = this;
switch (_that) {
case _EmergencyContactResponse():
return $default(_that.personalContacts,_that.defaultContacts);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<PersonalContact> personalContacts,  List<DefaultContact> defaultContacts)?  $default,) {final _that = this;
switch (_that) {
case _EmergencyContactResponse() when $default != null:
return $default(_that.personalContacts,_that.defaultContacts);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EmergencyContactResponse implements EmergencyContactResponse {
  const _EmergencyContactResponse({final  List<PersonalContact> personalContacts = const [], final  List<DefaultContact> defaultContacts = const []}): _personalContacts = personalContacts,_defaultContacts = defaultContacts;
  factory _EmergencyContactResponse.fromJson(Map<String, dynamic> json) => _$EmergencyContactResponseFromJson(json);

 final  List<PersonalContact> _personalContacts;
@override@JsonKey() List<PersonalContact> get personalContacts {
  if (_personalContacts is EqualUnmodifiableListView) return _personalContacts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_personalContacts);
}

 final  List<DefaultContact> _defaultContacts;
@override@JsonKey() List<DefaultContact> get defaultContacts {
  if (_defaultContacts is EqualUnmodifiableListView) return _defaultContacts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_defaultContacts);
}


/// Create a copy of EmergencyContactResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EmergencyContactResponseCopyWith<_EmergencyContactResponse> get copyWith => __$EmergencyContactResponseCopyWithImpl<_EmergencyContactResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EmergencyContactResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EmergencyContactResponse&&const DeepCollectionEquality().equals(other._personalContacts, _personalContacts)&&const DeepCollectionEquality().equals(other._defaultContacts, _defaultContacts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_personalContacts),const DeepCollectionEquality().hash(_defaultContacts));

@override
String toString() {
  return 'EmergencyContactResponse(personalContacts: $personalContacts, defaultContacts: $defaultContacts)';
}


}

/// @nodoc
abstract mixin class _$EmergencyContactResponseCopyWith<$Res> implements $EmergencyContactResponseCopyWith<$Res> {
  factory _$EmergencyContactResponseCopyWith(_EmergencyContactResponse value, $Res Function(_EmergencyContactResponse) _then) = __$EmergencyContactResponseCopyWithImpl;
@override @useResult
$Res call({
 List<PersonalContact> personalContacts, List<DefaultContact> defaultContacts
});




}
/// @nodoc
class __$EmergencyContactResponseCopyWithImpl<$Res>
    implements _$EmergencyContactResponseCopyWith<$Res> {
  __$EmergencyContactResponseCopyWithImpl(this._self, this._then);

  final _EmergencyContactResponse _self;
  final $Res Function(_EmergencyContactResponse) _then;

/// Create a copy of EmergencyContactResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? personalContacts = null,Object? defaultContacts = null,}) {
  return _then(_EmergencyContactResponse(
personalContacts: null == personalContacts ? _self._personalContacts : personalContacts // ignore: cast_nullable_to_non_nullable
as List<PersonalContact>,defaultContacts: null == defaultContacts ? _self._defaultContacts : defaultContacts // ignore: cast_nullable_to_non_nullable
as List<DefaultContact>,
  ));
}


}


/// @nodoc
mixin _$PersonalContact {

 String get id; String get phoneNumber; String get contactName;@JsonKey(name: 'createdAt', fromJson: _parseInt) int? get createdAtInt;
/// Create a copy of PersonalContact
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PersonalContactCopyWith<PersonalContact> get copyWith => _$PersonalContactCopyWithImpl<PersonalContact>(this as PersonalContact, _$identity);

  /// Serializes this PersonalContact to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PersonalContact&&(identical(other.id, id) || other.id == id)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.contactName, contactName) || other.contactName == contactName)&&(identical(other.createdAtInt, createdAtInt) || other.createdAtInt == createdAtInt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,phoneNumber,contactName,createdAtInt);

@override
String toString() {
  return 'PersonalContact(id: $id, phoneNumber: $phoneNumber, contactName: $contactName, createdAtInt: $createdAtInt)';
}


}

/// @nodoc
abstract mixin class $PersonalContactCopyWith<$Res>  {
  factory $PersonalContactCopyWith(PersonalContact value, $Res Function(PersonalContact) _then) = _$PersonalContactCopyWithImpl;
@useResult
$Res call({
 String id, String phoneNumber, String contactName,@JsonKey(name: 'createdAt', fromJson: _parseInt) int? createdAtInt
});




}
/// @nodoc
class _$PersonalContactCopyWithImpl<$Res>
    implements $PersonalContactCopyWith<$Res> {
  _$PersonalContactCopyWithImpl(this._self, this._then);

  final PersonalContact _self;
  final $Res Function(PersonalContact) _then;

/// Create a copy of PersonalContact
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? phoneNumber = null,Object? contactName = null,Object? createdAtInt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,phoneNumber: null == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String,contactName: null == contactName ? _self.contactName : contactName // ignore: cast_nullable_to_non_nullable
as String,createdAtInt: freezed == createdAtInt ? _self.createdAtInt : createdAtInt // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [PersonalContact].
extension PersonalContactPatterns on PersonalContact {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PersonalContact value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PersonalContact() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PersonalContact value)  $default,){
final _that = this;
switch (_that) {
case _PersonalContact():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PersonalContact value)?  $default,){
final _that = this;
switch (_that) {
case _PersonalContact() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String phoneNumber,  String contactName, @JsonKey(name: 'createdAt', fromJson: _parseInt)  int? createdAtInt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PersonalContact() when $default != null:
return $default(_that.id,_that.phoneNumber,_that.contactName,_that.createdAtInt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String phoneNumber,  String contactName, @JsonKey(name: 'createdAt', fromJson: _parseInt)  int? createdAtInt)  $default,) {final _that = this;
switch (_that) {
case _PersonalContact():
return $default(_that.id,_that.phoneNumber,_that.contactName,_that.createdAtInt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String phoneNumber,  String contactName, @JsonKey(name: 'createdAt', fromJson: _parseInt)  int? createdAtInt)?  $default,) {final _that = this;
switch (_that) {
case _PersonalContact() when $default != null:
return $default(_that.id,_that.phoneNumber,_that.contactName,_that.createdAtInt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PersonalContact implements PersonalContact {
  const _PersonalContact({required this.id, required this.phoneNumber, required this.contactName, @JsonKey(name: 'createdAt', fromJson: _parseInt) this.createdAtInt});
  factory _PersonalContact.fromJson(Map<String, dynamic> json) => _$PersonalContactFromJson(json);

@override final  String id;
@override final  String phoneNumber;
@override final  String contactName;
@override@JsonKey(name: 'createdAt', fromJson: _parseInt) final  int? createdAtInt;

/// Create a copy of PersonalContact
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PersonalContactCopyWith<_PersonalContact> get copyWith => __$PersonalContactCopyWithImpl<_PersonalContact>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PersonalContactToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PersonalContact&&(identical(other.id, id) || other.id == id)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.contactName, contactName) || other.contactName == contactName)&&(identical(other.createdAtInt, createdAtInt) || other.createdAtInt == createdAtInt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,phoneNumber,contactName,createdAtInt);

@override
String toString() {
  return 'PersonalContact(id: $id, phoneNumber: $phoneNumber, contactName: $contactName, createdAtInt: $createdAtInt)';
}


}

/// @nodoc
abstract mixin class _$PersonalContactCopyWith<$Res> implements $PersonalContactCopyWith<$Res> {
  factory _$PersonalContactCopyWith(_PersonalContact value, $Res Function(_PersonalContact) _then) = __$PersonalContactCopyWithImpl;
@override @useResult
$Res call({
 String id, String phoneNumber, String contactName,@JsonKey(name: 'createdAt', fromJson: _parseInt) int? createdAtInt
});




}
/// @nodoc
class __$PersonalContactCopyWithImpl<$Res>
    implements _$PersonalContactCopyWith<$Res> {
  __$PersonalContactCopyWithImpl(this._self, this._then);

  final _PersonalContact _self;
  final $Res Function(_PersonalContact) _then;

/// Create a copy of PersonalContact
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? phoneNumber = null,Object? contactName = null,Object? createdAtInt = freezed,}) {
  return _then(_PersonalContact(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,phoneNumber: null == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String,contactName: null == contactName ? _self.contactName : contactName // ignore: cast_nullable_to_non_nullable
as String,createdAtInt: freezed == createdAtInt ? _self.createdAtInt : createdAtInt // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$DefaultContact {

 String get id; String get name; String get phoneNumber; String get description;@JsonKey(name: 'createdAt', fromJson: _parseInt) int? get createdAtInt;@JsonKey(name: 'updatedAt', fromJson: _parseInt) int? get updatedAtInt;
/// Create a copy of DefaultContact
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DefaultContactCopyWith<DefaultContact> get copyWith => _$DefaultContactCopyWithImpl<DefaultContact>(this as DefaultContact, _$identity);

  /// Serializes this DefaultContact to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DefaultContact&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.description, description) || other.description == description)&&(identical(other.createdAtInt, createdAtInt) || other.createdAtInt == createdAtInt)&&(identical(other.updatedAtInt, updatedAtInt) || other.updatedAtInt == updatedAtInt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,phoneNumber,description,createdAtInt,updatedAtInt);

@override
String toString() {
  return 'DefaultContact(id: $id, name: $name, phoneNumber: $phoneNumber, description: $description, createdAtInt: $createdAtInt, updatedAtInt: $updatedAtInt)';
}


}

/// @nodoc
abstract mixin class $DefaultContactCopyWith<$Res>  {
  factory $DefaultContactCopyWith(DefaultContact value, $Res Function(DefaultContact) _then) = _$DefaultContactCopyWithImpl;
@useResult
$Res call({
 String id, String name, String phoneNumber, String description,@JsonKey(name: 'createdAt', fromJson: _parseInt) int? createdAtInt,@JsonKey(name: 'updatedAt', fromJson: _parseInt) int? updatedAtInt
});




}
/// @nodoc
class _$DefaultContactCopyWithImpl<$Res>
    implements $DefaultContactCopyWith<$Res> {
  _$DefaultContactCopyWithImpl(this._self, this._then);

  final DefaultContact _self;
  final $Res Function(DefaultContact) _then;

/// Create a copy of DefaultContact
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? phoneNumber = null,Object? description = null,Object? createdAtInt = freezed,Object? updatedAtInt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,phoneNumber: null == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,createdAtInt: freezed == createdAtInt ? _self.createdAtInt : createdAtInt // ignore: cast_nullable_to_non_nullable
as int?,updatedAtInt: freezed == updatedAtInt ? _self.updatedAtInt : updatedAtInt // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [DefaultContact].
extension DefaultContactPatterns on DefaultContact {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DefaultContact value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DefaultContact() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DefaultContact value)  $default,){
final _that = this;
switch (_that) {
case _DefaultContact():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DefaultContact value)?  $default,){
final _that = this;
switch (_that) {
case _DefaultContact() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String phoneNumber,  String description, @JsonKey(name: 'createdAt', fromJson: _parseInt)  int? createdAtInt, @JsonKey(name: 'updatedAt', fromJson: _parseInt)  int? updatedAtInt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DefaultContact() when $default != null:
return $default(_that.id,_that.name,_that.phoneNumber,_that.description,_that.createdAtInt,_that.updatedAtInt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String phoneNumber,  String description, @JsonKey(name: 'createdAt', fromJson: _parseInt)  int? createdAtInt, @JsonKey(name: 'updatedAt', fromJson: _parseInt)  int? updatedAtInt)  $default,) {final _that = this;
switch (_that) {
case _DefaultContact():
return $default(_that.id,_that.name,_that.phoneNumber,_that.description,_that.createdAtInt,_that.updatedAtInt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String phoneNumber,  String description, @JsonKey(name: 'createdAt', fromJson: _parseInt)  int? createdAtInt, @JsonKey(name: 'updatedAt', fromJson: _parseInt)  int? updatedAtInt)?  $default,) {final _that = this;
switch (_that) {
case _DefaultContact() when $default != null:
return $default(_that.id,_that.name,_that.phoneNumber,_that.description,_that.createdAtInt,_that.updatedAtInt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DefaultContact implements DefaultContact {
  const _DefaultContact({required this.id, required this.name, required this.phoneNumber, required this.description, @JsonKey(name: 'createdAt', fromJson: _parseInt) this.createdAtInt, @JsonKey(name: 'updatedAt', fromJson: _parseInt) this.updatedAtInt});
  factory _DefaultContact.fromJson(Map<String, dynamic> json) => _$DefaultContactFromJson(json);

@override final  String id;
@override final  String name;
@override final  String phoneNumber;
@override final  String description;
@override@JsonKey(name: 'createdAt', fromJson: _parseInt) final  int? createdAtInt;
@override@JsonKey(name: 'updatedAt', fromJson: _parseInt) final  int? updatedAtInt;

/// Create a copy of DefaultContact
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DefaultContactCopyWith<_DefaultContact> get copyWith => __$DefaultContactCopyWithImpl<_DefaultContact>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DefaultContactToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DefaultContact&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.description, description) || other.description == description)&&(identical(other.createdAtInt, createdAtInt) || other.createdAtInt == createdAtInt)&&(identical(other.updatedAtInt, updatedAtInt) || other.updatedAtInt == updatedAtInt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,phoneNumber,description,createdAtInt,updatedAtInt);

@override
String toString() {
  return 'DefaultContact(id: $id, name: $name, phoneNumber: $phoneNumber, description: $description, createdAtInt: $createdAtInt, updatedAtInt: $updatedAtInt)';
}


}

/// @nodoc
abstract mixin class _$DefaultContactCopyWith<$Res> implements $DefaultContactCopyWith<$Res> {
  factory _$DefaultContactCopyWith(_DefaultContact value, $Res Function(_DefaultContact) _then) = __$DefaultContactCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String phoneNumber, String description,@JsonKey(name: 'createdAt', fromJson: _parseInt) int? createdAtInt,@JsonKey(name: 'updatedAt', fromJson: _parseInt) int? updatedAtInt
});




}
/// @nodoc
class __$DefaultContactCopyWithImpl<$Res>
    implements _$DefaultContactCopyWith<$Res> {
  __$DefaultContactCopyWithImpl(this._self, this._then);

  final _DefaultContact _self;
  final $Res Function(_DefaultContact) _then;

/// Create a copy of DefaultContact
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? phoneNumber = null,Object? description = null,Object? createdAtInt = freezed,Object? updatedAtInt = freezed,}) {
  return _then(_DefaultContact(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,phoneNumber: null == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,createdAtInt: freezed == createdAtInt ? _self.createdAtInt : createdAtInt // ignore: cast_nullable_to_non_nullable
as int?,updatedAtInt: freezed == updatedAtInt ? _self.updatedAtInt : updatedAtInt // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
