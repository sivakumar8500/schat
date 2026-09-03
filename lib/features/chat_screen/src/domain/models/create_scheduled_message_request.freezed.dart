// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'create_scheduled_message_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CreateScheduledMessageRequest {

 String get conversationId; String get messageType; String? get parentMessageId; Map<String, dynamic> get content; Map<String, dynamic> get security; Map<String, dynamic> get viewControl; Map<String, dynamic> get expiry; Map<String, dynamic>? get callMeta; String get scheduledAt;
/// Create a copy of CreateScheduledMessageRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreateScheduledMessageRequestCopyWith<CreateScheduledMessageRequest> get copyWith => _$CreateScheduledMessageRequestCopyWithImpl<CreateScheduledMessageRequest>(this as CreateScheduledMessageRequest, _$identity);

  /// Serializes this CreateScheduledMessageRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreateScheduledMessageRequest&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.messageType, messageType) || other.messageType == messageType)&&(identical(other.parentMessageId, parentMessageId) || other.parentMessageId == parentMessageId)&&const DeepCollectionEquality().equals(other.content, content)&&const DeepCollectionEquality().equals(other.security, security)&&const DeepCollectionEquality().equals(other.viewControl, viewControl)&&const DeepCollectionEquality().equals(other.expiry, expiry)&&const DeepCollectionEquality().equals(other.callMeta, callMeta)&&(identical(other.scheduledAt, scheduledAt) || other.scheduledAt == scheduledAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,conversationId,messageType,parentMessageId,const DeepCollectionEquality().hash(content),const DeepCollectionEquality().hash(security),const DeepCollectionEquality().hash(viewControl),const DeepCollectionEquality().hash(expiry),const DeepCollectionEquality().hash(callMeta),scheduledAt);

@override
String toString() {
  return 'CreateScheduledMessageRequest(conversationId: $conversationId, messageType: $messageType, parentMessageId: $parentMessageId, content: $content, security: $security, viewControl: $viewControl, expiry: $expiry, callMeta: $callMeta, scheduledAt: $scheduledAt)';
}


}

/// @nodoc
abstract mixin class $CreateScheduledMessageRequestCopyWith<$Res>  {
  factory $CreateScheduledMessageRequestCopyWith(CreateScheduledMessageRequest value, $Res Function(CreateScheduledMessageRequest) _then) = _$CreateScheduledMessageRequestCopyWithImpl;
@useResult
$Res call({
 String conversationId, String messageType, String? parentMessageId, Map<String, dynamic> content, Map<String, dynamic> security, Map<String, dynamic> viewControl, Map<String, dynamic> expiry, Map<String, dynamic>? callMeta, String scheduledAt
});




}
/// @nodoc
class _$CreateScheduledMessageRequestCopyWithImpl<$Res>
    implements $CreateScheduledMessageRequestCopyWith<$Res> {
  _$CreateScheduledMessageRequestCopyWithImpl(this._self, this._then);

  final CreateScheduledMessageRequest _self;
  final $Res Function(CreateScheduledMessageRequest) _then;

/// Create a copy of CreateScheduledMessageRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? conversationId = null,Object? messageType = null,Object? parentMessageId = freezed,Object? content = null,Object? security = null,Object? viewControl = null,Object? expiry = null,Object? callMeta = freezed,Object? scheduledAt = null,}) {
  return _then(_self.copyWith(
conversationId: null == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as String,messageType: null == messageType ? _self.messageType : messageType // ignore: cast_nullable_to_non_nullable
as String,parentMessageId: freezed == parentMessageId ? _self.parentMessageId : parentMessageId // ignore: cast_nullable_to_non_nullable
as String?,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,security: null == security ? _self.security : security // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,viewControl: null == viewControl ? _self.viewControl : viewControl // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,expiry: null == expiry ? _self.expiry : expiry // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,callMeta: freezed == callMeta ? _self.callMeta : callMeta // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,scheduledAt: null == scheduledAt ? _self.scheduledAt : scheduledAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CreateScheduledMessageRequest].
extension CreateScheduledMessageRequestPatterns on CreateScheduledMessageRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CreateScheduledMessageRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CreateScheduledMessageRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CreateScheduledMessageRequest value)  $default,){
final _that = this;
switch (_that) {
case _CreateScheduledMessageRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CreateScheduledMessageRequest value)?  $default,){
final _that = this;
switch (_that) {
case _CreateScheduledMessageRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String conversationId,  String messageType,  String? parentMessageId,  Map<String, dynamic> content,  Map<String, dynamic> security,  Map<String, dynamic> viewControl,  Map<String, dynamic> expiry,  Map<String, dynamic>? callMeta,  String scheduledAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CreateScheduledMessageRequest() when $default != null:
return $default(_that.conversationId,_that.messageType,_that.parentMessageId,_that.content,_that.security,_that.viewControl,_that.expiry,_that.callMeta,_that.scheduledAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String conversationId,  String messageType,  String? parentMessageId,  Map<String, dynamic> content,  Map<String, dynamic> security,  Map<String, dynamic> viewControl,  Map<String, dynamic> expiry,  Map<String, dynamic>? callMeta,  String scheduledAt)  $default,) {final _that = this;
switch (_that) {
case _CreateScheduledMessageRequest():
return $default(_that.conversationId,_that.messageType,_that.parentMessageId,_that.content,_that.security,_that.viewControl,_that.expiry,_that.callMeta,_that.scheduledAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String conversationId,  String messageType,  String? parentMessageId,  Map<String, dynamic> content,  Map<String, dynamic> security,  Map<String, dynamic> viewControl,  Map<String, dynamic> expiry,  Map<String, dynamic>? callMeta,  String scheduledAt)?  $default,) {final _that = this;
switch (_that) {
case _CreateScheduledMessageRequest() when $default != null:
return $default(_that.conversationId,_that.messageType,_that.parentMessageId,_that.content,_that.security,_that.viewControl,_that.expiry,_that.callMeta,_that.scheduledAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CreateScheduledMessageRequest implements CreateScheduledMessageRequest {
  const _CreateScheduledMessageRequest({required this.conversationId, this.messageType = 'text', this.parentMessageId, final  Map<String, dynamic> content = const {}, final  Map<String, dynamic> security = const {}, final  Map<String, dynamic> viewControl = const {}, final  Map<String, dynamic> expiry = const {}, final  Map<String, dynamic>? callMeta, required this.scheduledAt}): _content = content,_security = security,_viewControl = viewControl,_expiry = expiry,_callMeta = callMeta;
  factory _CreateScheduledMessageRequest.fromJson(Map<String, dynamic> json) => _$CreateScheduledMessageRequestFromJson(json);

@override final  String conversationId;
@override@JsonKey() final  String messageType;
@override final  String? parentMessageId;
 final  Map<String, dynamic> _content;
@override@JsonKey() Map<String, dynamic> get content {
  if (_content is EqualUnmodifiableMapView) return _content;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_content);
}

 final  Map<String, dynamic> _security;
@override@JsonKey() Map<String, dynamic> get security {
  if (_security is EqualUnmodifiableMapView) return _security;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_security);
}

 final  Map<String, dynamic> _viewControl;
@override@JsonKey() Map<String, dynamic> get viewControl {
  if (_viewControl is EqualUnmodifiableMapView) return _viewControl;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_viewControl);
}

 final  Map<String, dynamic> _expiry;
@override@JsonKey() Map<String, dynamic> get expiry {
  if (_expiry is EqualUnmodifiableMapView) return _expiry;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_expiry);
}

 final  Map<String, dynamic>? _callMeta;
@override Map<String, dynamic>? get callMeta {
  final value = _callMeta;
  if (value == null) return null;
  if (_callMeta is EqualUnmodifiableMapView) return _callMeta;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override final  String scheduledAt;

/// Create a copy of CreateScheduledMessageRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreateScheduledMessageRequestCopyWith<_CreateScheduledMessageRequest> get copyWith => __$CreateScheduledMessageRequestCopyWithImpl<_CreateScheduledMessageRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CreateScheduledMessageRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreateScheduledMessageRequest&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.messageType, messageType) || other.messageType == messageType)&&(identical(other.parentMessageId, parentMessageId) || other.parentMessageId == parentMessageId)&&const DeepCollectionEquality().equals(other._content, _content)&&const DeepCollectionEquality().equals(other._security, _security)&&const DeepCollectionEquality().equals(other._viewControl, _viewControl)&&const DeepCollectionEquality().equals(other._expiry, _expiry)&&const DeepCollectionEquality().equals(other._callMeta, _callMeta)&&(identical(other.scheduledAt, scheduledAt) || other.scheduledAt == scheduledAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,conversationId,messageType,parentMessageId,const DeepCollectionEquality().hash(_content),const DeepCollectionEquality().hash(_security),const DeepCollectionEquality().hash(_viewControl),const DeepCollectionEquality().hash(_expiry),const DeepCollectionEquality().hash(_callMeta),scheduledAt);

@override
String toString() {
  return 'CreateScheduledMessageRequest(conversationId: $conversationId, messageType: $messageType, parentMessageId: $parentMessageId, content: $content, security: $security, viewControl: $viewControl, expiry: $expiry, callMeta: $callMeta, scheduledAt: $scheduledAt)';
}


}

/// @nodoc
abstract mixin class _$CreateScheduledMessageRequestCopyWith<$Res> implements $CreateScheduledMessageRequestCopyWith<$Res> {
  factory _$CreateScheduledMessageRequestCopyWith(_CreateScheduledMessageRequest value, $Res Function(_CreateScheduledMessageRequest) _then) = __$CreateScheduledMessageRequestCopyWithImpl;
@override @useResult
$Res call({
 String conversationId, String messageType, String? parentMessageId, Map<String, dynamic> content, Map<String, dynamic> security, Map<String, dynamic> viewControl, Map<String, dynamic> expiry, Map<String, dynamic>? callMeta, String scheduledAt
});




}
/// @nodoc
class __$CreateScheduledMessageRequestCopyWithImpl<$Res>
    implements _$CreateScheduledMessageRequestCopyWith<$Res> {
  __$CreateScheduledMessageRequestCopyWithImpl(this._self, this._then);

  final _CreateScheduledMessageRequest _self;
  final $Res Function(_CreateScheduledMessageRequest) _then;

/// Create a copy of CreateScheduledMessageRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? conversationId = null,Object? messageType = null,Object? parentMessageId = freezed,Object? content = null,Object? security = null,Object? viewControl = null,Object? expiry = null,Object? callMeta = freezed,Object? scheduledAt = null,}) {
  return _then(_CreateScheduledMessageRequest(
conversationId: null == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as String,messageType: null == messageType ? _self.messageType : messageType // ignore: cast_nullable_to_non_nullable
as String,parentMessageId: freezed == parentMessageId ? _self.parentMessageId : parentMessageId // ignore: cast_nullable_to_non_nullable
as String?,content: null == content ? _self._content : content // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,security: null == security ? _self._security : security // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,viewControl: null == viewControl ? _self._viewControl : viewControl // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,expiry: null == expiry ? _self._expiry : expiry // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,callMeta: freezed == callMeta ? _self._callMeta : callMeta // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,scheduledAt: null == scheduledAt ? _self.scheduledAt : scheduledAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
