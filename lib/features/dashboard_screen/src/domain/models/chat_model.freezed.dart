// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ChatModel {

@JsonKey(name: '_id', includeIfNull: false) String get id;@JsonKey(name: 'is_group') bool get isGroup;@JsonKey(name: 'group_name') String? get groupName;@JsonKey(name: 'group_description') String? get groupDescription;@JsonKey(name: 'created_at') String get createdAt;@JsonKey(name: 'updated_at') String get updatedAt; RecipientModel get recipient;@JsonKey(name: 'last_message') LastMessageModel? get lastMessage;@JsonKey(name: 'unread_count') int get unreadCount;@JsonKey(name: 'isHidden') bool get isHidden;@JsonKey(name: 'isHided') bool get isHided;@JsonKey(name: 'is_muted') bool get isMuted;@JsonKey(name: 'is_favorite') bool get isFavorite;@JsonKey(name: 'themeColor') ThemeColorModel? get themeColor;@JsonKey(name: 'disappearing_timer') int? get disappearingTimer;@JsonKey(includeFromJson: false, includeToJson: false) bool get isTyping;
/// Create a copy of ChatModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatModelCopyWith<ChatModel> get copyWith => _$ChatModelCopyWithImpl<ChatModel>(this as ChatModel, _$identity);

  /// Serializes this ChatModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatModel&&(identical(other.id, id) || other.id == id)&&(identical(other.isGroup, isGroup) || other.isGroup == isGroup)&&(identical(other.groupName, groupName) || other.groupName == groupName)&&(identical(other.groupDescription, groupDescription) || other.groupDescription == groupDescription)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.recipient, recipient) || other.recipient == recipient)&&(identical(other.lastMessage, lastMessage) || other.lastMessage == lastMessage)&&(identical(other.unreadCount, unreadCount) || other.unreadCount == unreadCount)&&(identical(other.isHidden, isHidden) || other.isHidden == isHidden)&&(identical(other.isHided, isHided) || other.isHided == isHided)&&(identical(other.isMuted, isMuted) || other.isMuted == isMuted)&&(identical(other.isFavorite, isFavorite) || other.isFavorite == isFavorite)&&(identical(other.themeColor, themeColor) || other.themeColor == themeColor)&&(identical(other.disappearingTimer, disappearingTimer) || other.disappearingTimer == disappearingTimer)&&(identical(other.isTyping, isTyping) || other.isTyping == isTyping));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,isGroup,groupName,groupDescription,createdAt,updatedAt,recipient,lastMessage,unreadCount,isHidden,isHided,isMuted,isFavorite,themeColor,disappearingTimer,isTyping);

@override
String toString() {
  return 'ChatModel(id: $id, isGroup: $isGroup, groupName: $groupName, groupDescription: $groupDescription, createdAt: $createdAt, updatedAt: $updatedAt, recipient: $recipient, lastMessage: $lastMessage, unreadCount: $unreadCount, isHidden: $isHidden, isHided: $isHided, isMuted: $isMuted, isFavorite: $isFavorite, themeColor: $themeColor, disappearingTimer: $disappearingTimer, isTyping: $isTyping)';
}


}

/// @nodoc
abstract mixin class $ChatModelCopyWith<$Res>  {
  factory $ChatModelCopyWith(ChatModel value, $Res Function(ChatModel) _then) = _$ChatModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: '_id', includeIfNull: false) String id,@JsonKey(name: 'is_group') bool isGroup,@JsonKey(name: 'group_name') String? groupName,@JsonKey(name: 'group_description') String? groupDescription,@JsonKey(name: 'created_at') String createdAt,@JsonKey(name: 'updated_at') String updatedAt, RecipientModel recipient,@JsonKey(name: 'last_message') LastMessageModel? lastMessage,@JsonKey(name: 'unread_count') int unreadCount,@JsonKey(name: 'isHidden') bool isHidden,@JsonKey(name: 'isHided') bool isHided,@JsonKey(name: 'is_muted') bool isMuted,@JsonKey(name: 'is_favorite') bool isFavorite,@JsonKey(name: 'themeColor') ThemeColorModel? themeColor,@JsonKey(name: 'disappearing_timer') int? disappearingTimer,@JsonKey(includeFromJson: false, includeToJson: false) bool isTyping
});


$RecipientModelCopyWith<$Res> get recipient;$LastMessageModelCopyWith<$Res>? get lastMessage;

}
/// @nodoc
class _$ChatModelCopyWithImpl<$Res>
    implements $ChatModelCopyWith<$Res> {
  _$ChatModelCopyWithImpl(this._self, this._then);

  final ChatModel _self;
  final $Res Function(ChatModel) _then;

/// Create a copy of ChatModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? isGroup = null,Object? groupName = freezed,Object? groupDescription = freezed,Object? createdAt = null,Object? updatedAt = null,Object? recipient = null,Object? lastMessage = freezed,Object? unreadCount = null,Object? isHidden = null,Object? isHided = null,Object? isMuted = null,Object? isFavorite = null,Object? themeColor = freezed,Object? disappearingTimer = freezed,Object? isTyping = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,isGroup: null == isGroup ? _self.isGroup : isGroup // ignore: cast_nullable_to_non_nullable
as bool,groupName: freezed == groupName ? _self.groupName : groupName // ignore: cast_nullable_to_non_nullable
as String?,groupDescription: freezed == groupDescription ? _self.groupDescription : groupDescription // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,recipient: null == recipient ? _self.recipient : recipient // ignore: cast_nullable_to_non_nullable
as RecipientModel,lastMessage: freezed == lastMessage ? _self.lastMessage : lastMessage // ignore: cast_nullable_to_non_nullable
as LastMessageModel?,unreadCount: null == unreadCount ? _self.unreadCount : unreadCount // ignore: cast_nullable_to_non_nullable
as int,isHidden: null == isHidden ? _self.isHidden : isHidden // ignore: cast_nullable_to_non_nullable
as bool,isHided: null == isHided ? _self.isHided : isHided // ignore: cast_nullable_to_non_nullable
as bool,isMuted: null == isMuted ? _self.isMuted : isMuted // ignore: cast_nullable_to_non_nullable
as bool,isFavorite: null == isFavorite ? _self.isFavorite : isFavorite // ignore: cast_nullable_to_non_nullable
as bool,themeColor: freezed == themeColor ? _self.themeColor : themeColor // ignore: cast_nullable_to_non_nullable
as ThemeColorModel?,disappearingTimer: freezed == disappearingTimer ? _self.disappearingTimer : disappearingTimer // ignore: cast_nullable_to_non_nullable
as int?,isTyping: null == isTyping ? _self.isTyping : isTyping // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of ChatModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RecipientModelCopyWith<$Res> get recipient {
  
  return $RecipientModelCopyWith<$Res>(_self.recipient, (value) {
    return _then(_self.copyWith(recipient: value));
  });
}/// Create a copy of ChatModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LastMessageModelCopyWith<$Res>? get lastMessage {
    if (_self.lastMessage == null) {
    return null;
  }

  return $LastMessageModelCopyWith<$Res>(_self.lastMessage!, (value) {
    return _then(_self.copyWith(lastMessage: value));
  });
}
}


/// Adds pattern-matching-related methods to [ChatModel].
extension ChatModelPatterns on ChatModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatModel value)  $default,){
final _that = this;
switch (_that) {
case _ChatModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatModel value)?  $default,){
final _that = this;
switch (_that) {
case _ChatModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: '_id', includeIfNull: false)  String id, @JsonKey(name: 'is_group')  bool isGroup, @JsonKey(name: 'group_name')  String? groupName, @JsonKey(name: 'group_description')  String? groupDescription, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'updated_at')  String updatedAt,  RecipientModel recipient, @JsonKey(name: 'last_message')  LastMessageModel? lastMessage, @JsonKey(name: 'unread_count')  int unreadCount, @JsonKey(name: 'isHidden')  bool isHidden, @JsonKey(name: 'isHided')  bool isHided, @JsonKey(name: 'is_muted')  bool isMuted, @JsonKey(name: 'is_favorite')  bool isFavorite, @JsonKey(name: 'themeColor')  ThemeColorModel? themeColor, @JsonKey(name: 'disappearing_timer')  int? disappearingTimer, @JsonKey(includeFromJson: false, includeToJson: false)  bool isTyping)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatModel() when $default != null:
return $default(_that.id,_that.isGroup,_that.groupName,_that.groupDescription,_that.createdAt,_that.updatedAt,_that.recipient,_that.lastMessage,_that.unreadCount,_that.isHidden,_that.isHided,_that.isMuted,_that.isFavorite,_that.themeColor,_that.disappearingTimer,_that.isTyping);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: '_id', includeIfNull: false)  String id, @JsonKey(name: 'is_group')  bool isGroup, @JsonKey(name: 'group_name')  String? groupName, @JsonKey(name: 'group_description')  String? groupDescription, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'updated_at')  String updatedAt,  RecipientModel recipient, @JsonKey(name: 'last_message')  LastMessageModel? lastMessage, @JsonKey(name: 'unread_count')  int unreadCount, @JsonKey(name: 'isHidden')  bool isHidden, @JsonKey(name: 'isHided')  bool isHided, @JsonKey(name: 'is_muted')  bool isMuted, @JsonKey(name: 'is_favorite')  bool isFavorite, @JsonKey(name: 'themeColor')  ThemeColorModel? themeColor, @JsonKey(name: 'disappearing_timer')  int? disappearingTimer, @JsonKey(includeFromJson: false, includeToJson: false)  bool isTyping)  $default,) {final _that = this;
switch (_that) {
case _ChatModel():
return $default(_that.id,_that.isGroup,_that.groupName,_that.groupDescription,_that.createdAt,_that.updatedAt,_that.recipient,_that.lastMessage,_that.unreadCount,_that.isHidden,_that.isHided,_that.isMuted,_that.isFavorite,_that.themeColor,_that.disappearingTimer,_that.isTyping);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: '_id', includeIfNull: false)  String id, @JsonKey(name: 'is_group')  bool isGroup, @JsonKey(name: 'group_name')  String? groupName, @JsonKey(name: 'group_description')  String? groupDescription, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'updated_at')  String updatedAt,  RecipientModel recipient, @JsonKey(name: 'last_message')  LastMessageModel? lastMessage, @JsonKey(name: 'unread_count')  int unreadCount, @JsonKey(name: 'isHidden')  bool isHidden, @JsonKey(name: 'isHided')  bool isHided, @JsonKey(name: 'is_muted')  bool isMuted, @JsonKey(name: 'is_favorite')  bool isFavorite, @JsonKey(name: 'themeColor')  ThemeColorModel? themeColor, @JsonKey(name: 'disappearing_timer')  int? disappearingTimer, @JsonKey(includeFromJson: false, includeToJson: false)  bool isTyping)?  $default,) {final _that = this;
switch (_that) {
case _ChatModel() when $default != null:
return $default(_that.id,_that.isGroup,_that.groupName,_that.groupDescription,_that.createdAt,_that.updatedAt,_that.recipient,_that.lastMessage,_that.unreadCount,_that.isHidden,_that.isHided,_that.isMuted,_that.isFavorite,_that.themeColor,_that.disappearingTimer,_that.isTyping);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChatModel implements ChatModel {
  const _ChatModel({@JsonKey(name: '_id', includeIfNull: false) this.id = '', @JsonKey(name: 'is_group') this.isGroup = false, @JsonKey(name: 'group_name') this.groupName, @JsonKey(name: 'group_description') this.groupDescription, @JsonKey(name: 'created_at') this.createdAt = '', @JsonKey(name: 'updated_at') this.updatedAt = '', required this.recipient, @JsonKey(name: 'last_message') this.lastMessage, @JsonKey(name: 'unread_count') this.unreadCount = 0, @JsonKey(name: 'isHidden') this.isHidden = false, @JsonKey(name: 'isHided') this.isHided = false, @JsonKey(name: 'is_muted') this.isMuted = false, @JsonKey(name: 'is_favorite') this.isFavorite = false, @JsonKey(name: 'themeColor') this.themeColor, @JsonKey(name: 'disappearing_timer') this.disappearingTimer, @JsonKey(includeFromJson: false, includeToJson: false) this.isTyping = false});
  factory _ChatModel.fromJson(Map<String, dynamic> json) => _$ChatModelFromJson(json);

@override@JsonKey(name: '_id', includeIfNull: false) final  String id;
@override@JsonKey(name: 'is_group') final  bool isGroup;
@override@JsonKey(name: 'group_name') final  String? groupName;
@override@JsonKey(name: 'group_description') final  String? groupDescription;
@override@JsonKey(name: 'created_at') final  String createdAt;
@override@JsonKey(name: 'updated_at') final  String updatedAt;
@override final  RecipientModel recipient;
@override@JsonKey(name: 'last_message') final  LastMessageModel? lastMessage;
@override@JsonKey(name: 'unread_count') final  int unreadCount;
@override@JsonKey(name: 'isHidden') final  bool isHidden;
@override@JsonKey(name: 'isHided') final  bool isHided;
@override@JsonKey(name: 'is_muted') final  bool isMuted;
@override@JsonKey(name: 'is_favorite') final  bool isFavorite;
@override@JsonKey(name: 'themeColor') final  ThemeColorModel? themeColor;
@override@JsonKey(name: 'disappearing_timer') final  int? disappearingTimer;
@override@JsonKey(includeFromJson: false, includeToJson: false) final  bool isTyping;

/// Create a copy of ChatModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatModelCopyWith<_ChatModel> get copyWith => __$ChatModelCopyWithImpl<_ChatModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatModel&&(identical(other.id, id) || other.id == id)&&(identical(other.isGroup, isGroup) || other.isGroup == isGroup)&&(identical(other.groupName, groupName) || other.groupName == groupName)&&(identical(other.groupDescription, groupDescription) || other.groupDescription == groupDescription)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.recipient, recipient) || other.recipient == recipient)&&(identical(other.lastMessage, lastMessage) || other.lastMessage == lastMessage)&&(identical(other.unreadCount, unreadCount) || other.unreadCount == unreadCount)&&(identical(other.isHidden, isHidden) || other.isHidden == isHidden)&&(identical(other.isHided, isHided) || other.isHided == isHided)&&(identical(other.isMuted, isMuted) || other.isMuted == isMuted)&&(identical(other.isFavorite, isFavorite) || other.isFavorite == isFavorite)&&(identical(other.themeColor, themeColor) || other.themeColor == themeColor)&&(identical(other.disappearingTimer, disappearingTimer) || other.disappearingTimer == disappearingTimer)&&(identical(other.isTyping, isTyping) || other.isTyping == isTyping));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,isGroup,groupName,groupDescription,createdAt,updatedAt,recipient,lastMessage,unreadCount,isHidden,isHided,isMuted,isFavorite,themeColor,disappearingTimer,isTyping);

@override
String toString() {
  return 'ChatModel(id: $id, isGroup: $isGroup, groupName: $groupName, groupDescription: $groupDescription, createdAt: $createdAt, updatedAt: $updatedAt, recipient: $recipient, lastMessage: $lastMessage, unreadCount: $unreadCount, isHidden: $isHidden, isHided: $isHided, isMuted: $isMuted, isFavorite: $isFavorite, themeColor: $themeColor, disappearingTimer: $disappearingTimer, isTyping: $isTyping)';
}


}

/// @nodoc
abstract mixin class _$ChatModelCopyWith<$Res> implements $ChatModelCopyWith<$Res> {
  factory _$ChatModelCopyWith(_ChatModel value, $Res Function(_ChatModel) _then) = __$ChatModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: '_id', includeIfNull: false) String id,@JsonKey(name: 'is_group') bool isGroup,@JsonKey(name: 'group_name') String? groupName,@JsonKey(name: 'group_description') String? groupDescription,@JsonKey(name: 'created_at') String createdAt,@JsonKey(name: 'updated_at') String updatedAt, RecipientModel recipient,@JsonKey(name: 'last_message') LastMessageModel? lastMessage,@JsonKey(name: 'unread_count') int unreadCount,@JsonKey(name: 'isHidden') bool isHidden,@JsonKey(name: 'isHided') bool isHided,@JsonKey(name: 'is_muted') bool isMuted,@JsonKey(name: 'is_favorite') bool isFavorite,@JsonKey(name: 'themeColor') ThemeColorModel? themeColor,@JsonKey(name: 'disappearing_timer') int? disappearingTimer,@JsonKey(includeFromJson: false, includeToJson: false) bool isTyping
});


@override $RecipientModelCopyWith<$Res> get recipient;@override $LastMessageModelCopyWith<$Res>? get lastMessage;

}
/// @nodoc
class __$ChatModelCopyWithImpl<$Res>
    implements _$ChatModelCopyWith<$Res> {
  __$ChatModelCopyWithImpl(this._self, this._then);

  final _ChatModel _self;
  final $Res Function(_ChatModel) _then;

/// Create a copy of ChatModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? isGroup = null,Object? groupName = freezed,Object? groupDescription = freezed,Object? createdAt = null,Object? updatedAt = null,Object? recipient = null,Object? lastMessage = freezed,Object? unreadCount = null,Object? isHidden = null,Object? isHided = null,Object? isMuted = null,Object? isFavorite = null,Object? themeColor = freezed,Object? disappearingTimer = freezed,Object? isTyping = null,}) {
  return _then(_ChatModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,isGroup: null == isGroup ? _self.isGroup : isGroup // ignore: cast_nullable_to_non_nullable
as bool,groupName: freezed == groupName ? _self.groupName : groupName // ignore: cast_nullable_to_non_nullable
as String?,groupDescription: freezed == groupDescription ? _self.groupDescription : groupDescription // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,recipient: null == recipient ? _self.recipient : recipient // ignore: cast_nullable_to_non_nullable
as RecipientModel,lastMessage: freezed == lastMessage ? _self.lastMessage : lastMessage // ignore: cast_nullable_to_non_nullable
as LastMessageModel?,unreadCount: null == unreadCount ? _self.unreadCount : unreadCount // ignore: cast_nullable_to_non_nullable
as int,isHidden: null == isHidden ? _self.isHidden : isHidden // ignore: cast_nullable_to_non_nullable
as bool,isHided: null == isHided ? _self.isHided : isHided // ignore: cast_nullable_to_non_nullable
as bool,isMuted: null == isMuted ? _self.isMuted : isMuted // ignore: cast_nullable_to_non_nullable
as bool,isFavorite: null == isFavorite ? _self.isFavorite : isFavorite // ignore: cast_nullable_to_non_nullable
as bool,themeColor: freezed == themeColor ? _self.themeColor : themeColor // ignore: cast_nullable_to_non_nullable
as ThemeColorModel?,disappearingTimer: freezed == disappearingTimer ? _self.disappearingTimer : disappearingTimer // ignore: cast_nullable_to_non_nullable
as int?,isTyping: null == isTyping ? _self.isTyping : isTyping // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of ChatModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RecipientModelCopyWith<$Res> get recipient {
  
  return $RecipientModelCopyWith<$Res>(_self.recipient, (value) {
    return _then(_self.copyWith(recipient: value));
  });
}/// Create a copy of ChatModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LastMessageModelCopyWith<$Res>? get lastMessage {
    if (_self.lastMessage == null) {
    return null;
  }

  return $LastMessageModelCopyWith<$Res>(_self.lastMessage!, (value) {
    return _then(_self.copyWith(lastMessage: value));
  });
}
}

// dart format on
