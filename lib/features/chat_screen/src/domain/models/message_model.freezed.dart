// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'message_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MessageModel {

 String get id; String get chatId; String get type;// text, image, video, audio, doc, pdf, gif, call, video_call
 String get senderId; String get receiverId; MessageContent get content; MessageSecurity get security; MessageViewControl get viewControl; MessageExpiry get expiry; MessageCallMeta? get callMeta; List<String> get deletedFor; bool get isDeletedForEveryone; int get createdAt; int get updatedAt;
/// Create a copy of MessageModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MessageModelCopyWith<MessageModel> get copyWith => _$MessageModelCopyWithImpl<MessageModel>(this as MessageModel, _$identity);

  /// Serializes this MessageModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MessageModel&&(identical(other.id, id) || other.id == id)&&(identical(other.chatId, chatId) || other.chatId == chatId)&&(identical(other.type, type) || other.type == type)&&(identical(other.senderId, senderId) || other.senderId == senderId)&&(identical(other.receiverId, receiverId) || other.receiverId == receiverId)&&(identical(other.content, content) || other.content == content)&&(identical(other.security, security) || other.security == security)&&(identical(other.viewControl, viewControl) || other.viewControl == viewControl)&&(identical(other.expiry, expiry) || other.expiry == expiry)&&(identical(other.callMeta, callMeta) || other.callMeta == callMeta)&&const DeepCollectionEquality().equals(other.deletedFor, deletedFor)&&(identical(other.isDeletedForEveryone, isDeletedForEveryone) || other.isDeletedForEveryone == isDeletedForEveryone)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,chatId,type,senderId,receiverId,content,security,viewControl,expiry,callMeta,const DeepCollectionEquality().hash(deletedFor),isDeletedForEveryone,createdAt,updatedAt);

@override
String toString() {
  return 'MessageModel(id: $id, chatId: $chatId, type: $type, senderId: $senderId, receiverId: $receiverId, content: $content, security: $security, viewControl: $viewControl, expiry: $expiry, callMeta: $callMeta, deletedFor: $deletedFor, isDeletedForEveryone: $isDeletedForEveryone, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $MessageModelCopyWith<$Res>  {
  factory $MessageModelCopyWith(MessageModel value, $Res Function(MessageModel) _then) = _$MessageModelCopyWithImpl;
@useResult
$Res call({
 String id, String chatId, String type, String senderId, String receiverId, MessageContent content, MessageSecurity security, MessageViewControl viewControl, MessageExpiry expiry, MessageCallMeta? callMeta, List<String> deletedFor, bool isDeletedForEveryone, int createdAt, int updatedAt
});


$MessageContentCopyWith<$Res> get content;$MessageSecurityCopyWith<$Res> get security;$MessageViewControlCopyWith<$Res> get viewControl;$MessageExpiryCopyWith<$Res> get expiry;$MessageCallMetaCopyWith<$Res>? get callMeta;

}
/// @nodoc
class _$MessageModelCopyWithImpl<$Res>
    implements $MessageModelCopyWith<$Res> {
  _$MessageModelCopyWithImpl(this._self, this._then);

  final MessageModel _self;
  final $Res Function(MessageModel) _then;

/// Create a copy of MessageModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? chatId = null,Object? type = null,Object? senderId = null,Object? receiverId = null,Object? content = null,Object? security = null,Object? viewControl = null,Object? expiry = null,Object? callMeta = freezed,Object? deletedFor = null,Object? isDeletedForEveryone = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,chatId: null == chatId ? _self.chatId : chatId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,senderId: null == senderId ? _self.senderId : senderId // ignore: cast_nullable_to_non_nullable
as String,receiverId: null == receiverId ? _self.receiverId : receiverId // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as MessageContent,security: null == security ? _self.security : security // ignore: cast_nullable_to_non_nullable
as MessageSecurity,viewControl: null == viewControl ? _self.viewControl : viewControl // ignore: cast_nullable_to_non_nullable
as MessageViewControl,expiry: null == expiry ? _self.expiry : expiry // ignore: cast_nullable_to_non_nullable
as MessageExpiry,callMeta: freezed == callMeta ? _self.callMeta : callMeta // ignore: cast_nullable_to_non_nullable
as MessageCallMeta?,deletedFor: null == deletedFor ? _self.deletedFor : deletedFor // ignore: cast_nullable_to_non_nullable
as List<String>,isDeletedForEveryone: null == isDeletedForEveryone ? _self.isDeletedForEveryone : isDeletedForEveryone // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of MessageModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MessageContentCopyWith<$Res> get content {
  
  return $MessageContentCopyWith<$Res>(_self.content, (value) {
    return _then(_self.copyWith(content: value));
  });
}/// Create a copy of MessageModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MessageSecurityCopyWith<$Res> get security {
  
  return $MessageSecurityCopyWith<$Res>(_self.security, (value) {
    return _then(_self.copyWith(security: value));
  });
}/// Create a copy of MessageModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MessageViewControlCopyWith<$Res> get viewControl {
  
  return $MessageViewControlCopyWith<$Res>(_self.viewControl, (value) {
    return _then(_self.copyWith(viewControl: value));
  });
}/// Create a copy of MessageModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MessageExpiryCopyWith<$Res> get expiry {
  
  return $MessageExpiryCopyWith<$Res>(_self.expiry, (value) {
    return _then(_self.copyWith(expiry: value));
  });
}/// Create a copy of MessageModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MessageCallMetaCopyWith<$Res>? get callMeta {
    if (_self.callMeta == null) {
    return null;
  }

  return $MessageCallMetaCopyWith<$Res>(_self.callMeta!, (value) {
    return _then(_self.copyWith(callMeta: value));
  });
}
}


/// Adds pattern-matching-related methods to [MessageModel].
extension MessageModelPatterns on MessageModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MessageModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MessageModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MessageModel value)  $default,){
final _that = this;
switch (_that) {
case _MessageModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MessageModel value)?  $default,){
final _that = this;
switch (_that) {
case _MessageModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String chatId,  String type,  String senderId,  String receiverId,  MessageContent content,  MessageSecurity security,  MessageViewControl viewControl,  MessageExpiry expiry,  MessageCallMeta? callMeta,  List<String> deletedFor,  bool isDeletedForEveryone,  int createdAt,  int updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MessageModel() when $default != null:
return $default(_that.id,_that.chatId,_that.type,_that.senderId,_that.receiverId,_that.content,_that.security,_that.viewControl,_that.expiry,_that.callMeta,_that.deletedFor,_that.isDeletedForEveryone,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String chatId,  String type,  String senderId,  String receiverId,  MessageContent content,  MessageSecurity security,  MessageViewControl viewControl,  MessageExpiry expiry,  MessageCallMeta? callMeta,  List<String> deletedFor,  bool isDeletedForEveryone,  int createdAt,  int updatedAt)  $default,) {final _that = this;
switch (_that) {
case _MessageModel():
return $default(_that.id,_that.chatId,_that.type,_that.senderId,_that.receiverId,_that.content,_that.security,_that.viewControl,_that.expiry,_that.callMeta,_that.deletedFor,_that.isDeletedForEveryone,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String chatId,  String type,  String senderId,  String receiverId,  MessageContent content,  MessageSecurity security,  MessageViewControl viewControl,  MessageExpiry expiry,  MessageCallMeta? callMeta,  List<String> deletedFor,  bool isDeletedForEveryone,  int createdAt,  int updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _MessageModel() when $default != null:
return $default(_that.id,_that.chatId,_that.type,_that.senderId,_that.receiverId,_that.content,_that.security,_that.viewControl,_that.expiry,_that.callMeta,_that.deletedFor,_that.isDeletedForEveryone,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MessageModel implements MessageModel {
  const _MessageModel({required this.id, required this.chatId, required this.type, required this.senderId, required this.receiverId, required this.content, required this.security, required this.viewControl, required this.expiry, this.callMeta, final  List<String> deletedFor = const [], this.isDeletedForEveryone = false, required this.createdAt, required this.updatedAt}): _deletedFor = deletedFor;
  factory _MessageModel.fromJson(Map<String, dynamic> json) => _$MessageModelFromJson(json);

@override final  String id;
@override final  String chatId;
@override final  String type;
// text, image, video, audio, doc, pdf, gif, call, video_call
@override final  String senderId;
@override final  String receiverId;
@override final  MessageContent content;
@override final  MessageSecurity security;
@override final  MessageViewControl viewControl;
@override final  MessageExpiry expiry;
@override final  MessageCallMeta? callMeta;
 final  List<String> _deletedFor;
@override@JsonKey() List<String> get deletedFor {
  if (_deletedFor is EqualUnmodifiableListView) return _deletedFor;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_deletedFor);
}

@override@JsonKey() final  bool isDeletedForEveryone;
@override final  int createdAt;
@override final  int updatedAt;

/// Create a copy of MessageModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MessageModelCopyWith<_MessageModel> get copyWith => __$MessageModelCopyWithImpl<_MessageModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MessageModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MessageModel&&(identical(other.id, id) || other.id == id)&&(identical(other.chatId, chatId) || other.chatId == chatId)&&(identical(other.type, type) || other.type == type)&&(identical(other.senderId, senderId) || other.senderId == senderId)&&(identical(other.receiverId, receiverId) || other.receiverId == receiverId)&&(identical(other.content, content) || other.content == content)&&(identical(other.security, security) || other.security == security)&&(identical(other.viewControl, viewControl) || other.viewControl == viewControl)&&(identical(other.expiry, expiry) || other.expiry == expiry)&&(identical(other.callMeta, callMeta) || other.callMeta == callMeta)&&const DeepCollectionEquality().equals(other._deletedFor, _deletedFor)&&(identical(other.isDeletedForEveryone, isDeletedForEveryone) || other.isDeletedForEveryone == isDeletedForEveryone)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,chatId,type,senderId,receiverId,content,security,viewControl,expiry,callMeta,const DeepCollectionEquality().hash(_deletedFor),isDeletedForEveryone,createdAt,updatedAt);

@override
String toString() {
  return 'MessageModel(id: $id, chatId: $chatId, type: $type, senderId: $senderId, receiverId: $receiverId, content: $content, security: $security, viewControl: $viewControl, expiry: $expiry, callMeta: $callMeta, deletedFor: $deletedFor, isDeletedForEveryone: $isDeletedForEveryone, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$MessageModelCopyWith<$Res> implements $MessageModelCopyWith<$Res> {
  factory _$MessageModelCopyWith(_MessageModel value, $Res Function(_MessageModel) _then) = __$MessageModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String chatId, String type, String senderId, String receiverId, MessageContent content, MessageSecurity security, MessageViewControl viewControl, MessageExpiry expiry, MessageCallMeta? callMeta, List<String> deletedFor, bool isDeletedForEveryone, int createdAt, int updatedAt
});


@override $MessageContentCopyWith<$Res> get content;@override $MessageSecurityCopyWith<$Res> get security;@override $MessageViewControlCopyWith<$Res> get viewControl;@override $MessageExpiryCopyWith<$Res> get expiry;@override $MessageCallMetaCopyWith<$Res>? get callMeta;

}
/// @nodoc
class __$MessageModelCopyWithImpl<$Res>
    implements _$MessageModelCopyWith<$Res> {
  __$MessageModelCopyWithImpl(this._self, this._then);

  final _MessageModel _self;
  final $Res Function(_MessageModel) _then;

/// Create a copy of MessageModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? chatId = null,Object? type = null,Object? senderId = null,Object? receiverId = null,Object? content = null,Object? security = null,Object? viewControl = null,Object? expiry = null,Object? callMeta = freezed,Object? deletedFor = null,Object? isDeletedForEveryone = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_MessageModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,chatId: null == chatId ? _self.chatId : chatId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,senderId: null == senderId ? _self.senderId : senderId // ignore: cast_nullable_to_non_nullable
as String,receiverId: null == receiverId ? _self.receiverId : receiverId // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as MessageContent,security: null == security ? _self.security : security // ignore: cast_nullable_to_non_nullable
as MessageSecurity,viewControl: null == viewControl ? _self.viewControl : viewControl // ignore: cast_nullable_to_non_nullable
as MessageViewControl,expiry: null == expiry ? _self.expiry : expiry // ignore: cast_nullable_to_non_nullable
as MessageExpiry,callMeta: freezed == callMeta ? _self.callMeta : callMeta // ignore: cast_nullable_to_non_nullable
as MessageCallMeta?,deletedFor: null == deletedFor ? _self._deletedFor : deletedFor // ignore: cast_nullable_to_non_nullable
as List<String>,isDeletedForEveryone: null == isDeletedForEveryone ? _self.isDeletedForEveryone : isDeletedForEveryone // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of MessageModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MessageContentCopyWith<$Res> get content {
  
  return $MessageContentCopyWith<$Res>(_self.content, (value) {
    return _then(_self.copyWith(content: value));
  });
}/// Create a copy of MessageModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MessageSecurityCopyWith<$Res> get security {
  
  return $MessageSecurityCopyWith<$Res>(_self.security, (value) {
    return _then(_self.copyWith(security: value));
  });
}/// Create a copy of MessageModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MessageViewControlCopyWith<$Res> get viewControl {
  
  return $MessageViewControlCopyWith<$Res>(_self.viewControl, (value) {
    return _then(_self.copyWith(viewControl: value));
  });
}/// Create a copy of MessageModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MessageExpiryCopyWith<$Res> get expiry {
  
  return $MessageExpiryCopyWith<$Res>(_self.expiry, (value) {
    return _then(_self.copyWith(expiry: value));
  });
}/// Create a copy of MessageModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MessageCallMetaCopyWith<$Res>? get callMeta {
    if (_self.callMeta == null) {
    return null;
  }

  return $MessageCallMetaCopyWith<$Res>(_self.callMeta!, (value) {
    return _then(_self.copyWith(callMeta: value));
  });
}
}


/// @nodoc
mixin _$MessageContent {

 String? get text; String? get fileUrl; String? get thumbnail; String? get fileName; int? get fileSize; String? get mimeType; int? get duration;
/// Create a copy of MessageContent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MessageContentCopyWith<MessageContent> get copyWith => _$MessageContentCopyWithImpl<MessageContent>(this as MessageContent, _$identity);

  /// Serializes this MessageContent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MessageContent&&(identical(other.text, text) || other.text == text)&&(identical(other.fileUrl, fileUrl) || other.fileUrl == fileUrl)&&(identical(other.thumbnail, thumbnail) || other.thumbnail == thumbnail)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.fileSize, fileSize) || other.fileSize == fileSize)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType)&&(identical(other.duration, duration) || other.duration == duration));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,text,fileUrl,thumbnail,fileName,fileSize,mimeType,duration);

@override
String toString() {
  return 'MessageContent(text: $text, fileUrl: $fileUrl, thumbnail: $thumbnail, fileName: $fileName, fileSize: $fileSize, mimeType: $mimeType, duration: $duration)';
}


}

/// @nodoc
abstract mixin class $MessageContentCopyWith<$Res>  {
  factory $MessageContentCopyWith(MessageContent value, $Res Function(MessageContent) _then) = _$MessageContentCopyWithImpl;
@useResult
$Res call({
 String? text, String? fileUrl, String? thumbnail, String? fileName, int? fileSize, String? mimeType, int? duration
});




}
/// @nodoc
class _$MessageContentCopyWithImpl<$Res>
    implements $MessageContentCopyWith<$Res> {
  _$MessageContentCopyWithImpl(this._self, this._then);

  final MessageContent _self;
  final $Res Function(MessageContent) _then;

/// Create a copy of MessageContent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? text = freezed,Object? fileUrl = freezed,Object? thumbnail = freezed,Object? fileName = freezed,Object? fileSize = freezed,Object? mimeType = freezed,Object? duration = freezed,}) {
  return _then(_self.copyWith(
text: freezed == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String?,fileUrl: freezed == fileUrl ? _self.fileUrl : fileUrl // ignore: cast_nullable_to_non_nullable
as String?,thumbnail: freezed == thumbnail ? _self.thumbnail : thumbnail // ignore: cast_nullable_to_non_nullable
as String?,fileName: freezed == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String?,fileSize: freezed == fileSize ? _self.fileSize : fileSize // ignore: cast_nullable_to_non_nullable
as int?,mimeType: freezed == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String?,duration: freezed == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [MessageContent].
extension MessageContentPatterns on MessageContent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MessageContent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MessageContent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MessageContent value)  $default,){
final _that = this;
switch (_that) {
case _MessageContent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MessageContent value)?  $default,){
final _that = this;
switch (_that) {
case _MessageContent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? text,  String? fileUrl,  String? thumbnail,  String? fileName,  int? fileSize,  String? mimeType,  int? duration)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MessageContent() when $default != null:
return $default(_that.text,_that.fileUrl,_that.thumbnail,_that.fileName,_that.fileSize,_that.mimeType,_that.duration);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? text,  String? fileUrl,  String? thumbnail,  String? fileName,  int? fileSize,  String? mimeType,  int? duration)  $default,) {final _that = this;
switch (_that) {
case _MessageContent():
return $default(_that.text,_that.fileUrl,_that.thumbnail,_that.fileName,_that.fileSize,_that.mimeType,_that.duration);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? text,  String? fileUrl,  String? thumbnail,  String? fileName,  int? fileSize,  String? mimeType,  int? duration)?  $default,) {final _that = this;
switch (_that) {
case _MessageContent() when $default != null:
return $default(_that.text,_that.fileUrl,_that.thumbnail,_that.fileName,_that.fileSize,_that.mimeType,_that.duration);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MessageContent implements MessageContent {
  const _MessageContent({this.text, this.fileUrl, this.thumbnail, this.fileName, this.fileSize, this.mimeType, this.duration});
  factory _MessageContent.fromJson(Map<String, dynamic> json) => _$MessageContentFromJson(json);

@override final  String? text;
@override final  String? fileUrl;
@override final  String? thumbnail;
@override final  String? fileName;
@override final  int? fileSize;
@override final  String? mimeType;
@override final  int? duration;

/// Create a copy of MessageContent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MessageContentCopyWith<_MessageContent> get copyWith => __$MessageContentCopyWithImpl<_MessageContent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MessageContentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MessageContent&&(identical(other.text, text) || other.text == text)&&(identical(other.fileUrl, fileUrl) || other.fileUrl == fileUrl)&&(identical(other.thumbnail, thumbnail) || other.thumbnail == thumbnail)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.fileSize, fileSize) || other.fileSize == fileSize)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType)&&(identical(other.duration, duration) || other.duration == duration));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,text,fileUrl,thumbnail,fileName,fileSize,mimeType,duration);

@override
String toString() {
  return 'MessageContent(text: $text, fileUrl: $fileUrl, thumbnail: $thumbnail, fileName: $fileName, fileSize: $fileSize, mimeType: $mimeType, duration: $duration)';
}


}

/// @nodoc
abstract mixin class _$MessageContentCopyWith<$Res> implements $MessageContentCopyWith<$Res> {
  factory _$MessageContentCopyWith(_MessageContent value, $Res Function(_MessageContent) _then) = __$MessageContentCopyWithImpl;
@override @useResult
$Res call({
 String? text, String? fileUrl, String? thumbnail, String? fileName, int? fileSize, String? mimeType, int? duration
});




}
/// @nodoc
class __$MessageContentCopyWithImpl<$Res>
    implements _$MessageContentCopyWith<$Res> {
  __$MessageContentCopyWithImpl(this._self, this._then);

  final _MessageContent _self;
  final $Res Function(_MessageContent) _then;

/// Create a copy of MessageContent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? text = freezed,Object? fileUrl = freezed,Object? thumbnail = freezed,Object? fileName = freezed,Object? fileSize = freezed,Object? mimeType = freezed,Object? duration = freezed,}) {
  return _then(_MessageContent(
text: freezed == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String?,fileUrl: freezed == fileUrl ? _self.fileUrl : fileUrl // ignore: cast_nullable_to_non_nullable
as String?,thumbnail: freezed == thumbnail ? _self.thumbnail : thumbnail // ignore: cast_nullable_to_non_nullable
as String?,fileName: freezed == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String?,fileSize: freezed == fileSize ? _self.fileSize : fileSize // ignore: cast_nullable_to_non_nullable
as int?,mimeType: freezed == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String?,duration: freezed == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$MessageSecurity {

 bool get isLocked; List<String> get accessUsers; bool get allowDownload; bool get allowShare;
/// Create a copy of MessageSecurity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MessageSecurityCopyWith<MessageSecurity> get copyWith => _$MessageSecurityCopyWithImpl<MessageSecurity>(this as MessageSecurity, _$identity);

  /// Serializes this MessageSecurity to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MessageSecurity&&(identical(other.isLocked, isLocked) || other.isLocked == isLocked)&&const DeepCollectionEquality().equals(other.accessUsers, accessUsers)&&(identical(other.allowDownload, allowDownload) || other.allowDownload == allowDownload)&&(identical(other.allowShare, allowShare) || other.allowShare == allowShare));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isLocked,const DeepCollectionEquality().hash(accessUsers),allowDownload,allowShare);

@override
String toString() {
  return 'MessageSecurity(isLocked: $isLocked, accessUsers: $accessUsers, allowDownload: $allowDownload, allowShare: $allowShare)';
}


}

/// @nodoc
abstract mixin class $MessageSecurityCopyWith<$Res>  {
  factory $MessageSecurityCopyWith(MessageSecurity value, $Res Function(MessageSecurity) _then) = _$MessageSecurityCopyWithImpl;
@useResult
$Res call({
 bool isLocked, List<String> accessUsers, bool allowDownload, bool allowShare
});




}
/// @nodoc
class _$MessageSecurityCopyWithImpl<$Res>
    implements $MessageSecurityCopyWith<$Res> {
  _$MessageSecurityCopyWithImpl(this._self, this._then);

  final MessageSecurity _self;
  final $Res Function(MessageSecurity) _then;

/// Create a copy of MessageSecurity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isLocked = null,Object? accessUsers = null,Object? allowDownload = null,Object? allowShare = null,}) {
  return _then(_self.copyWith(
isLocked: null == isLocked ? _self.isLocked : isLocked // ignore: cast_nullable_to_non_nullable
as bool,accessUsers: null == accessUsers ? _self.accessUsers : accessUsers // ignore: cast_nullable_to_non_nullable
as List<String>,allowDownload: null == allowDownload ? _self.allowDownload : allowDownload // ignore: cast_nullable_to_non_nullable
as bool,allowShare: null == allowShare ? _self.allowShare : allowShare // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [MessageSecurity].
extension MessageSecurityPatterns on MessageSecurity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MessageSecurity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MessageSecurity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MessageSecurity value)  $default,){
final _that = this;
switch (_that) {
case _MessageSecurity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MessageSecurity value)?  $default,){
final _that = this;
switch (_that) {
case _MessageSecurity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isLocked,  List<String> accessUsers,  bool allowDownload,  bool allowShare)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MessageSecurity() when $default != null:
return $default(_that.isLocked,_that.accessUsers,_that.allowDownload,_that.allowShare);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isLocked,  List<String> accessUsers,  bool allowDownload,  bool allowShare)  $default,) {final _that = this;
switch (_that) {
case _MessageSecurity():
return $default(_that.isLocked,_that.accessUsers,_that.allowDownload,_that.allowShare);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isLocked,  List<String> accessUsers,  bool allowDownload,  bool allowShare)?  $default,) {final _that = this;
switch (_that) {
case _MessageSecurity() when $default != null:
return $default(_that.isLocked,_that.accessUsers,_that.allowDownload,_that.allowShare);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MessageSecurity implements MessageSecurity {
  const _MessageSecurity({required this.isLocked, required final  List<String> accessUsers, required this.allowDownload, required this.allowShare}): _accessUsers = accessUsers;
  factory _MessageSecurity.fromJson(Map<String, dynamic> json) => _$MessageSecurityFromJson(json);

@override final  bool isLocked;
 final  List<String> _accessUsers;
@override List<String> get accessUsers {
  if (_accessUsers is EqualUnmodifiableListView) return _accessUsers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_accessUsers);
}

@override final  bool allowDownload;
@override final  bool allowShare;

/// Create a copy of MessageSecurity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MessageSecurityCopyWith<_MessageSecurity> get copyWith => __$MessageSecurityCopyWithImpl<_MessageSecurity>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MessageSecurityToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MessageSecurity&&(identical(other.isLocked, isLocked) || other.isLocked == isLocked)&&const DeepCollectionEquality().equals(other._accessUsers, _accessUsers)&&(identical(other.allowDownload, allowDownload) || other.allowDownload == allowDownload)&&(identical(other.allowShare, allowShare) || other.allowShare == allowShare));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isLocked,const DeepCollectionEquality().hash(_accessUsers),allowDownload,allowShare);

@override
String toString() {
  return 'MessageSecurity(isLocked: $isLocked, accessUsers: $accessUsers, allowDownload: $allowDownload, allowShare: $allowShare)';
}


}

/// @nodoc
abstract mixin class _$MessageSecurityCopyWith<$Res> implements $MessageSecurityCopyWith<$Res> {
  factory _$MessageSecurityCopyWith(_MessageSecurity value, $Res Function(_MessageSecurity) _then) = __$MessageSecurityCopyWithImpl;
@override @useResult
$Res call({
 bool isLocked, List<String> accessUsers, bool allowDownload, bool allowShare
});




}
/// @nodoc
class __$MessageSecurityCopyWithImpl<$Res>
    implements _$MessageSecurityCopyWith<$Res> {
  __$MessageSecurityCopyWithImpl(this._self, this._then);

  final _MessageSecurity _self;
  final $Res Function(_MessageSecurity) _then;

/// Create a copy of MessageSecurity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isLocked = null,Object? accessUsers = null,Object? allowDownload = null,Object? allowShare = null,}) {
  return _then(_MessageSecurity(
isLocked: null == isLocked ? _self.isLocked : isLocked // ignore: cast_nullable_to_non_nullable
as bool,accessUsers: null == accessUsers ? _self._accessUsers : accessUsers // ignore: cast_nullable_to_non_nullable
as List<String>,allowDownload: null == allowDownload ? _self.allowDownload : allowDownload // ignore: cast_nullable_to_non_nullable
as bool,allowShare: null == allowShare ? _self.allowShare : allowShare // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$MessageViewControl {

 String get type;// once, etc.
 int get maxViews; List<String> get viewedBy; bool get isOpened; int? get openedAt;
/// Create a copy of MessageViewControl
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MessageViewControlCopyWith<MessageViewControl> get copyWith => _$MessageViewControlCopyWithImpl<MessageViewControl>(this as MessageViewControl, _$identity);

  /// Serializes this MessageViewControl to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MessageViewControl&&(identical(other.type, type) || other.type == type)&&(identical(other.maxViews, maxViews) || other.maxViews == maxViews)&&const DeepCollectionEquality().equals(other.viewedBy, viewedBy)&&(identical(other.isOpened, isOpened) || other.isOpened == isOpened)&&(identical(other.openedAt, openedAt) || other.openedAt == openedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,maxViews,const DeepCollectionEquality().hash(viewedBy),isOpened,openedAt);

@override
String toString() {
  return 'MessageViewControl(type: $type, maxViews: $maxViews, viewedBy: $viewedBy, isOpened: $isOpened, openedAt: $openedAt)';
}


}

/// @nodoc
abstract mixin class $MessageViewControlCopyWith<$Res>  {
  factory $MessageViewControlCopyWith(MessageViewControl value, $Res Function(MessageViewControl) _then) = _$MessageViewControlCopyWithImpl;
@useResult
$Res call({
 String type, int maxViews, List<String> viewedBy, bool isOpened, int? openedAt
});




}
/// @nodoc
class _$MessageViewControlCopyWithImpl<$Res>
    implements $MessageViewControlCopyWith<$Res> {
  _$MessageViewControlCopyWithImpl(this._self, this._then);

  final MessageViewControl _self;
  final $Res Function(MessageViewControl) _then;

/// Create a copy of MessageViewControl
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? maxViews = null,Object? viewedBy = null,Object? isOpened = null,Object? openedAt = freezed,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,maxViews: null == maxViews ? _self.maxViews : maxViews // ignore: cast_nullable_to_non_nullable
as int,viewedBy: null == viewedBy ? _self.viewedBy : viewedBy // ignore: cast_nullable_to_non_nullable
as List<String>,isOpened: null == isOpened ? _self.isOpened : isOpened // ignore: cast_nullable_to_non_nullable
as bool,openedAt: freezed == openedAt ? _self.openedAt : openedAt // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [MessageViewControl].
extension MessageViewControlPatterns on MessageViewControl {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MessageViewControl value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MessageViewControl() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MessageViewControl value)  $default,){
final _that = this;
switch (_that) {
case _MessageViewControl():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MessageViewControl value)?  $default,){
final _that = this;
switch (_that) {
case _MessageViewControl() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String type,  int maxViews,  List<String> viewedBy,  bool isOpened,  int? openedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MessageViewControl() when $default != null:
return $default(_that.type,_that.maxViews,_that.viewedBy,_that.isOpened,_that.openedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String type,  int maxViews,  List<String> viewedBy,  bool isOpened,  int? openedAt)  $default,) {final _that = this;
switch (_that) {
case _MessageViewControl():
return $default(_that.type,_that.maxViews,_that.viewedBy,_that.isOpened,_that.openedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String type,  int maxViews,  List<String> viewedBy,  bool isOpened,  int? openedAt)?  $default,) {final _that = this;
switch (_that) {
case _MessageViewControl() when $default != null:
return $default(_that.type,_that.maxViews,_that.viewedBy,_that.isOpened,_that.openedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MessageViewControl implements MessageViewControl {
  const _MessageViewControl({required this.type, required this.maxViews, required final  List<String> viewedBy, required this.isOpened, this.openedAt}): _viewedBy = viewedBy;
  factory _MessageViewControl.fromJson(Map<String, dynamic> json) => _$MessageViewControlFromJson(json);

@override final  String type;
// once, etc.
@override final  int maxViews;
 final  List<String> _viewedBy;
@override List<String> get viewedBy {
  if (_viewedBy is EqualUnmodifiableListView) return _viewedBy;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_viewedBy);
}

@override final  bool isOpened;
@override final  int? openedAt;

/// Create a copy of MessageViewControl
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MessageViewControlCopyWith<_MessageViewControl> get copyWith => __$MessageViewControlCopyWithImpl<_MessageViewControl>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MessageViewControlToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MessageViewControl&&(identical(other.type, type) || other.type == type)&&(identical(other.maxViews, maxViews) || other.maxViews == maxViews)&&const DeepCollectionEquality().equals(other._viewedBy, _viewedBy)&&(identical(other.isOpened, isOpened) || other.isOpened == isOpened)&&(identical(other.openedAt, openedAt) || other.openedAt == openedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,maxViews,const DeepCollectionEquality().hash(_viewedBy),isOpened,openedAt);

@override
String toString() {
  return 'MessageViewControl(type: $type, maxViews: $maxViews, viewedBy: $viewedBy, isOpened: $isOpened, openedAt: $openedAt)';
}


}

/// @nodoc
abstract mixin class _$MessageViewControlCopyWith<$Res> implements $MessageViewControlCopyWith<$Res> {
  factory _$MessageViewControlCopyWith(_MessageViewControl value, $Res Function(_MessageViewControl) _then) = __$MessageViewControlCopyWithImpl;
@override @useResult
$Res call({
 String type, int maxViews, List<String> viewedBy, bool isOpened, int? openedAt
});




}
/// @nodoc
class __$MessageViewControlCopyWithImpl<$Res>
    implements _$MessageViewControlCopyWith<$Res> {
  __$MessageViewControlCopyWithImpl(this._self, this._then);

  final _MessageViewControl _self;
  final $Res Function(_MessageViewControl) _then;

/// Create a copy of MessageViewControl
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? maxViews = null,Object? viewedBy = null,Object? isOpened = null,Object? openedAt = freezed,}) {
  return _then(_MessageViewControl(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,maxViews: null == maxViews ? _self.maxViews : maxViews // ignore: cast_nullable_to_non_nullable
as int,viewedBy: null == viewedBy ? _self._viewedBy : viewedBy // ignore: cast_nullable_to_non_nullable
as List<String>,isOpened: null == isOpened ? _self.isOpened : isOpened // ignore: cast_nullable_to_non_nullable
as bool,openedAt: freezed == openedAt ? _self.openedAt : openedAt // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$MessageExpiry {

 bool get isEnabled; int get expireAt;
/// Create a copy of MessageExpiry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MessageExpiryCopyWith<MessageExpiry> get copyWith => _$MessageExpiryCopyWithImpl<MessageExpiry>(this as MessageExpiry, _$identity);

  /// Serializes this MessageExpiry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MessageExpiry&&(identical(other.isEnabled, isEnabled) || other.isEnabled == isEnabled)&&(identical(other.expireAt, expireAt) || other.expireAt == expireAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isEnabled,expireAt);

@override
String toString() {
  return 'MessageExpiry(isEnabled: $isEnabled, expireAt: $expireAt)';
}


}

/// @nodoc
abstract mixin class $MessageExpiryCopyWith<$Res>  {
  factory $MessageExpiryCopyWith(MessageExpiry value, $Res Function(MessageExpiry) _then) = _$MessageExpiryCopyWithImpl;
@useResult
$Res call({
 bool isEnabled, int expireAt
});




}
/// @nodoc
class _$MessageExpiryCopyWithImpl<$Res>
    implements $MessageExpiryCopyWith<$Res> {
  _$MessageExpiryCopyWithImpl(this._self, this._then);

  final MessageExpiry _self;
  final $Res Function(MessageExpiry) _then;

/// Create a copy of MessageExpiry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isEnabled = null,Object? expireAt = null,}) {
  return _then(_self.copyWith(
isEnabled: null == isEnabled ? _self.isEnabled : isEnabled // ignore: cast_nullable_to_non_nullable
as bool,expireAt: null == expireAt ? _self.expireAt : expireAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [MessageExpiry].
extension MessageExpiryPatterns on MessageExpiry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MessageExpiry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MessageExpiry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MessageExpiry value)  $default,){
final _that = this;
switch (_that) {
case _MessageExpiry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MessageExpiry value)?  $default,){
final _that = this;
switch (_that) {
case _MessageExpiry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isEnabled,  int expireAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MessageExpiry() when $default != null:
return $default(_that.isEnabled,_that.expireAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isEnabled,  int expireAt)  $default,) {final _that = this;
switch (_that) {
case _MessageExpiry():
return $default(_that.isEnabled,_that.expireAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isEnabled,  int expireAt)?  $default,) {final _that = this;
switch (_that) {
case _MessageExpiry() when $default != null:
return $default(_that.isEnabled,_that.expireAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MessageExpiry implements MessageExpiry {
  const _MessageExpiry({required this.isEnabled, required this.expireAt});
  factory _MessageExpiry.fromJson(Map<String, dynamic> json) => _$MessageExpiryFromJson(json);

@override final  bool isEnabled;
@override final  int expireAt;

/// Create a copy of MessageExpiry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MessageExpiryCopyWith<_MessageExpiry> get copyWith => __$MessageExpiryCopyWithImpl<_MessageExpiry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MessageExpiryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MessageExpiry&&(identical(other.isEnabled, isEnabled) || other.isEnabled == isEnabled)&&(identical(other.expireAt, expireAt) || other.expireAt == expireAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isEnabled,expireAt);

@override
String toString() {
  return 'MessageExpiry(isEnabled: $isEnabled, expireAt: $expireAt)';
}


}

/// @nodoc
abstract mixin class _$MessageExpiryCopyWith<$Res> implements $MessageExpiryCopyWith<$Res> {
  factory _$MessageExpiryCopyWith(_MessageExpiry value, $Res Function(_MessageExpiry) _then) = __$MessageExpiryCopyWithImpl;
@override @useResult
$Res call({
 bool isEnabled, int expireAt
});




}
/// @nodoc
class __$MessageExpiryCopyWithImpl<$Res>
    implements _$MessageExpiryCopyWith<$Res> {
  __$MessageExpiryCopyWithImpl(this._self, this._then);

  final _MessageExpiry _self;
  final $Res Function(_MessageExpiry) _then;

/// Create a copy of MessageExpiry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isEnabled = null,Object? expireAt = null,}) {
  return _then(_MessageExpiry(
isEnabled: null == isEnabled ? _self.isEnabled : isEnabled // ignore: cast_nullable_to_non_nullable
as bool,expireAt: null == expireAt ? _self.expireAt : expireAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$MessageCallMeta {

 String? get callType; int? get duration; String? get status;
/// Create a copy of MessageCallMeta
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MessageCallMetaCopyWith<MessageCallMeta> get copyWith => _$MessageCallMetaCopyWithImpl<MessageCallMeta>(this as MessageCallMeta, _$identity);

  /// Serializes this MessageCallMeta to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MessageCallMeta&&(identical(other.callType, callType) || other.callType == callType)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,callType,duration,status);

@override
String toString() {
  return 'MessageCallMeta(callType: $callType, duration: $duration, status: $status)';
}


}

/// @nodoc
abstract mixin class $MessageCallMetaCopyWith<$Res>  {
  factory $MessageCallMetaCopyWith(MessageCallMeta value, $Res Function(MessageCallMeta) _then) = _$MessageCallMetaCopyWithImpl;
@useResult
$Res call({
 String? callType, int? duration, String? status
});




}
/// @nodoc
class _$MessageCallMetaCopyWithImpl<$Res>
    implements $MessageCallMetaCopyWith<$Res> {
  _$MessageCallMetaCopyWithImpl(this._self, this._then);

  final MessageCallMeta _self;
  final $Res Function(MessageCallMeta) _then;

/// Create a copy of MessageCallMeta
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? callType = freezed,Object? duration = freezed,Object? status = freezed,}) {
  return _then(_self.copyWith(
callType: freezed == callType ? _self.callType : callType // ignore: cast_nullable_to_non_nullable
as String?,duration: freezed == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as int?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [MessageCallMeta].
extension MessageCallMetaPatterns on MessageCallMeta {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MessageCallMeta value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MessageCallMeta() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MessageCallMeta value)  $default,){
final _that = this;
switch (_that) {
case _MessageCallMeta():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MessageCallMeta value)?  $default,){
final _that = this;
switch (_that) {
case _MessageCallMeta() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? callType,  int? duration,  String? status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MessageCallMeta() when $default != null:
return $default(_that.callType,_that.duration,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? callType,  int? duration,  String? status)  $default,) {final _that = this;
switch (_that) {
case _MessageCallMeta():
return $default(_that.callType,_that.duration,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? callType,  int? duration,  String? status)?  $default,) {final _that = this;
switch (_that) {
case _MessageCallMeta() when $default != null:
return $default(_that.callType,_that.duration,_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MessageCallMeta implements MessageCallMeta {
  const _MessageCallMeta({this.callType, this.duration, this.status});
  factory _MessageCallMeta.fromJson(Map<String, dynamic> json) => _$MessageCallMetaFromJson(json);

@override final  String? callType;
@override final  int? duration;
@override final  String? status;

/// Create a copy of MessageCallMeta
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MessageCallMetaCopyWith<_MessageCallMeta> get copyWith => __$MessageCallMetaCopyWithImpl<_MessageCallMeta>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MessageCallMetaToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MessageCallMeta&&(identical(other.callType, callType) || other.callType == callType)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,callType,duration,status);

@override
String toString() {
  return 'MessageCallMeta(callType: $callType, duration: $duration, status: $status)';
}


}

/// @nodoc
abstract mixin class _$MessageCallMetaCopyWith<$Res> implements $MessageCallMetaCopyWith<$Res> {
  factory _$MessageCallMetaCopyWith(_MessageCallMeta value, $Res Function(_MessageCallMeta) _then) = __$MessageCallMetaCopyWithImpl;
@override @useResult
$Res call({
 String? callType, int? duration, String? status
});




}
/// @nodoc
class __$MessageCallMetaCopyWithImpl<$Res>
    implements _$MessageCallMetaCopyWith<$Res> {
  __$MessageCallMetaCopyWithImpl(this._self, this._then);

  final _MessageCallMeta _self;
  final $Res Function(_MessageCallMeta) _then;

/// Create a copy of MessageCallMeta
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? callType = freezed,Object? duration = freezed,Object? status = freezed,}) {
  return _then(_MessageCallMeta(
callType: freezed == callType ? _self.callType : callType // ignore: cast_nullable_to_non_nullable
as String?,duration: freezed == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as int?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
