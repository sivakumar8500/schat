// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chats_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ChatsEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatsEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ChatsEvent()';
}


}

/// @nodoc
class $ChatsEventCopyWith<$Res>  {
$ChatsEventCopyWith(ChatsEvent _, $Res Function(ChatsEvent) __);
}


/// Adds pattern-matching-related methods to [ChatsEvent].
extension ChatsEventPatterns on ChatsEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( FetchChats value)?  fetchChats,TResult Function( CreateChat value)?  createChat,required TResult orElse(),}){
final _that = this;
switch (_that) {
case FetchChats() when fetchChats != null:
return fetchChats(_that);case CreateChat() when createChat != null:
return createChat(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( FetchChats value)  fetchChats,required TResult Function( CreateChat value)  createChat,}){
final _that = this;
switch (_that) {
case FetchChats():
return fetchChats(_that);case CreateChat():
return createChat(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( FetchChats value)?  fetchChats,TResult? Function( CreateChat value)?  createChat,}){
final _that = this;
switch (_that) {
case FetchChats() when fetchChats != null:
return fetchChats(_that);case CreateChat() when createChat != null:
return createChat(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  fetchChats,TResult Function( String participantId,  String contactName)?  createChat,required TResult orElse(),}) {final _that = this;
switch (_that) {
case FetchChats() when fetchChats != null:
return fetchChats();case CreateChat() when createChat != null:
return createChat(_that.participantId,_that.contactName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  fetchChats,required TResult Function( String participantId,  String contactName)  createChat,}) {final _that = this;
switch (_that) {
case FetchChats():
return fetchChats();case CreateChat():
return createChat(_that.participantId,_that.contactName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  fetchChats,TResult? Function( String participantId,  String contactName)?  createChat,}) {final _that = this;
switch (_that) {
case FetchChats() when fetchChats != null:
return fetchChats();case CreateChat() when createChat != null:
return createChat(_that.participantId,_that.contactName);case _:
  return null;

}
}

}

/// @nodoc


class FetchChats implements ChatsEvent {
  const FetchChats();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FetchChats);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ChatsEvent.fetchChats()';
}


}




/// @nodoc


class CreateChat implements ChatsEvent {
  const CreateChat({required this.participantId, required this.contactName});
  

 final  String participantId;
 final  String contactName;

/// Create a copy of ChatsEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreateChatCopyWith<CreateChat> get copyWith => _$CreateChatCopyWithImpl<CreateChat>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreateChat&&(identical(other.participantId, participantId) || other.participantId == participantId)&&(identical(other.contactName, contactName) || other.contactName == contactName));
}


@override
int get hashCode => Object.hash(runtimeType,participantId,contactName);

@override
String toString() {
  return 'ChatsEvent.createChat(participantId: $participantId, contactName: $contactName)';
}


}

/// @nodoc
abstract mixin class $CreateChatCopyWith<$Res> implements $ChatsEventCopyWith<$Res> {
  factory $CreateChatCopyWith(CreateChat value, $Res Function(CreateChat) _then) = _$CreateChatCopyWithImpl;
@useResult
$Res call({
 String participantId, String contactName
});




}
/// @nodoc
class _$CreateChatCopyWithImpl<$Res>
    implements $CreateChatCopyWith<$Res> {
  _$CreateChatCopyWithImpl(this._self, this._then);

  final CreateChat _self;
  final $Res Function(CreateChat) _then;

/// Create a copy of ChatsEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? participantId = null,Object? contactName = null,}) {
  return _then(CreateChat(
participantId: null == participantId ? _self.participantId : participantId // ignore: cast_nullable_to_non_nullable
as String,contactName: null == contactName ? _self.contactName : contactName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
