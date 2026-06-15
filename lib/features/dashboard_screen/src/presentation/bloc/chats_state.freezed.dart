// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chats_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ChatsState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatsState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ChatsState()';
}


}

/// @nodoc
class $ChatsStateCopyWith<$Res>  {
$ChatsStateCopyWith(ChatsState _, $Res Function(ChatsState) __);
}


/// Adds pattern-matching-related methods to [ChatsState].
extension ChatsStatePatterns on ChatsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ChatsInitial value)?  initial,TResult Function( ChatsLoading value)?  loading,TResult Function( ChatsLoaded value)?  loaded,TResult Function( ChatCreated value)?  chatCreated,TResult Function( ChatsError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ChatsInitial() when initial != null:
return initial(_that);case ChatsLoading() when loading != null:
return loading(_that);case ChatsLoaded() when loaded != null:
return loaded(_that);case ChatCreated() when chatCreated != null:
return chatCreated(_that);case ChatsError() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ChatsInitial value)  initial,required TResult Function( ChatsLoading value)  loading,required TResult Function( ChatsLoaded value)  loaded,required TResult Function( ChatCreated value)  chatCreated,required TResult Function( ChatsError value)  error,}){
final _that = this;
switch (_that) {
case ChatsInitial():
return initial(_that);case ChatsLoading():
return loading(_that);case ChatsLoaded():
return loaded(_that);case ChatCreated():
return chatCreated(_that);case ChatsError():
return error(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ChatsInitial value)?  initial,TResult? Function( ChatsLoading value)?  loading,TResult? Function( ChatsLoaded value)?  loaded,TResult? Function( ChatCreated value)?  chatCreated,TResult? Function( ChatsError value)?  error,}){
final _that = this;
switch (_that) {
case ChatsInitial() when initial != null:
return initial(_that);case ChatsLoading() when loading != null:
return loading(_that);case ChatsLoaded() when loaded != null:
return loaded(_that);case ChatCreated() when chatCreated != null:
return chatCreated(_that);case ChatsError() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( List<ChatModel> chats)?  loaded,TResult Function( ChatModel chat,  String contactName,  String? profilePictureUrl)?  chatCreated,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ChatsInitial() when initial != null:
return initial();case ChatsLoading() when loading != null:
return loading();case ChatsLoaded() when loaded != null:
return loaded(_that.chats);case ChatCreated() when chatCreated != null:
return chatCreated(_that.chat,_that.contactName,_that.profilePictureUrl);case ChatsError() when error != null:
return error(_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( List<ChatModel> chats)  loaded,required TResult Function( ChatModel chat,  String contactName,  String? profilePictureUrl)  chatCreated,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case ChatsInitial():
return initial();case ChatsLoading():
return loading();case ChatsLoaded():
return loaded(_that.chats);case ChatCreated():
return chatCreated(_that.chat,_that.contactName,_that.profilePictureUrl);case ChatsError():
return error(_that.message);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( List<ChatModel> chats)?  loaded,TResult? Function( ChatModel chat,  String contactName,  String? profilePictureUrl)?  chatCreated,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case ChatsInitial() when initial != null:
return initial();case ChatsLoading() when loading != null:
return loading();case ChatsLoaded() when loaded != null:
return loaded(_that.chats);case ChatCreated() when chatCreated != null:
return chatCreated(_that.chat,_that.contactName,_that.profilePictureUrl);case ChatsError() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class ChatsInitial implements ChatsState {
  const ChatsInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatsInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ChatsState.initial()';
}


}




/// @nodoc


class ChatsLoading implements ChatsState {
  const ChatsLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatsLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ChatsState.loading()';
}


}




/// @nodoc


class ChatsLoaded implements ChatsState {
  const ChatsLoaded(final  List<ChatModel> chats): _chats = chats;
  

 final  List<ChatModel> _chats;
 List<ChatModel> get chats {
  if (_chats is EqualUnmodifiableListView) return _chats;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_chats);
}


/// Create a copy of ChatsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatsLoadedCopyWith<ChatsLoaded> get copyWith => _$ChatsLoadedCopyWithImpl<ChatsLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatsLoaded&&const DeepCollectionEquality().equals(other._chats, _chats));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_chats));

@override
String toString() {
  return 'ChatsState.loaded(chats: $chats)';
}


}

/// @nodoc
abstract mixin class $ChatsLoadedCopyWith<$Res> implements $ChatsStateCopyWith<$Res> {
  factory $ChatsLoadedCopyWith(ChatsLoaded value, $Res Function(ChatsLoaded) _then) = _$ChatsLoadedCopyWithImpl;
@useResult
$Res call({
 List<ChatModel> chats
});




}
/// @nodoc
class _$ChatsLoadedCopyWithImpl<$Res>
    implements $ChatsLoadedCopyWith<$Res> {
  _$ChatsLoadedCopyWithImpl(this._self, this._then);

  final ChatsLoaded _self;
  final $Res Function(ChatsLoaded) _then;

/// Create a copy of ChatsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? chats = null,}) {
  return _then(ChatsLoaded(
null == chats ? _self._chats : chats // ignore: cast_nullable_to_non_nullable
as List<ChatModel>,
  ));
}


}

/// @nodoc


class ChatCreated implements ChatsState {
  const ChatCreated(this.chat, this.contactName, {this.profilePictureUrl});
  

 final  ChatModel chat;
 final  String contactName;
 final  String? profilePictureUrl;

/// Create a copy of ChatsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatCreatedCopyWith<ChatCreated> get copyWith => _$ChatCreatedCopyWithImpl<ChatCreated>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatCreated&&(identical(other.chat, chat) || other.chat == chat)&&(identical(other.contactName, contactName) || other.contactName == contactName)&&(identical(other.profilePictureUrl, profilePictureUrl) || other.profilePictureUrl == profilePictureUrl));
}


@override
int get hashCode => Object.hash(runtimeType,chat,contactName,profilePictureUrl);

@override
String toString() {
  return 'ChatsState.chatCreated(chat: $chat, contactName: $contactName, profilePictureUrl: $profilePictureUrl)';
}


}

/// @nodoc
abstract mixin class $ChatCreatedCopyWith<$Res> implements $ChatsStateCopyWith<$Res> {
  factory $ChatCreatedCopyWith(ChatCreated value, $Res Function(ChatCreated) _then) = _$ChatCreatedCopyWithImpl;
@useResult
$Res call({
 ChatModel chat, String contactName, String? profilePictureUrl
});


$ChatModelCopyWith<$Res> get chat;

}
/// @nodoc
class _$ChatCreatedCopyWithImpl<$Res>
    implements $ChatCreatedCopyWith<$Res> {
  _$ChatCreatedCopyWithImpl(this._self, this._then);

  final ChatCreated _self;
  final $Res Function(ChatCreated) _then;

/// Create a copy of ChatsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? chat = null,Object? contactName = null,Object? profilePictureUrl = freezed,}) {
  return _then(ChatCreated(
null == chat ? _self.chat : chat // ignore: cast_nullable_to_non_nullable
as ChatModel,null == contactName ? _self.contactName : contactName // ignore: cast_nullable_to_non_nullable
as String,profilePictureUrl: freezed == profilePictureUrl ? _self.profilePictureUrl : profilePictureUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of ChatsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatModelCopyWith<$Res> get chat {
  
  return $ChatModelCopyWith<$Res>(_self.chat, (value) {
    return _then(_self.copyWith(chat: value));
  });
}
}

/// @nodoc


class ChatsError implements ChatsState {
  const ChatsError(this.message);
  

 final  String message;

/// Create a copy of ChatsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatsErrorCopyWith<ChatsError> get copyWith => _$ChatsErrorCopyWithImpl<ChatsError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatsError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'ChatsState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $ChatsErrorCopyWith<$Res> implements $ChatsStateCopyWith<$Res> {
  factory $ChatsErrorCopyWith(ChatsError value, $Res Function(ChatsError) _then) = _$ChatsErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$ChatsErrorCopyWithImpl<$Res>
    implements $ChatsErrorCopyWith<$Res> {
  _$ChatsErrorCopyWithImpl(this._self, this._then);

  final ChatsError _self;
  final $Res Function(ChatsError) _then;

/// Create a copy of ChatsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(ChatsError(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
