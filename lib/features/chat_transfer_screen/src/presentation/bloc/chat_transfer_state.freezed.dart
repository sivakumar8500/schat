// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_transfer_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ChatTransferState {

 ChatTransferStatus get status; List<ChatViewRequestModel> get requests; List<ChatModel> get monitoredConversations; ChatViewUserModel? get selectedTargetUser; String get currentUserId; String? get errorMessage; String? get successMessage; ChatViewRequestModel? get newlyReceivedRequest;
/// Create a copy of ChatTransferState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatTransferStateCopyWith<ChatTransferState> get copyWith => _$ChatTransferStateCopyWithImpl<ChatTransferState>(this as ChatTransferState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatTransferState&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.requests, requests)&&const DeepCollectionEquality().equals(other.monitoredConversations, monitoredConversations)&&(identical(other.selectedTargetUser, selectedTargetUser) || other.selectedTargetUser == selectedTargetUser)&&(identical(other.currentUserId, currentUserId) || other.currentUserId == currentUserId)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.successMessage, successMessage) || other.successMessage == successMessage)&&(identical(other.newlyReceivedRequest, newlyReceivedRequest) || other.newlyReceivedRequest == newlyReceivedRequest));
}


@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(requests),const DeepCollectionEquality().hash(monitoredConversations),selectedTargetUser,currentUserId,errorMessage,successMessage,newlyReceivedRequest);

@override
String toString() {
  return 'ChatTransferState(status: $status, requests: $requests, monitoredConversations: $monitoredConversations, selectedTargetUser: $selectedTargetUser, currentUserId: $currentUserId, errorMessage: $errorMessage, successMessage: $successMessage, newlyReceivedRequest: $newlyReceivedRequest)';
}


}

/// @nodoc
abstract mixin class $ChatTransferStateCopyWith<$Res>  {
  factory $ChatTransferStateCopyWith(ChatTransferState value, $Res Function(ChatTransferState) _then) = _$ChatTransferStateCopyWithImpl;
@useResult
$Res call({
 ChatTransferStatus status, List<ChatViewRequestModel> requests, List<ChatModel> monitoredConversations, ChatViewUserModel? selectedTargetUser, String currentUserId, String? errorMessage, String? successMessage, ChatViewRequestModel? newlyReceivedRequest
});


$ChatViewUserModelCopyWith<$Res>? get selectedTargetUser;$ChatViewRequestModelCopyWith<$Res>? get newlyReceivedRequest;

}
/// @nodoc
class _$ChatTransferStateCopyWithImpl<$Res>
    implements $ChatTransferStateCopyWith<$Res> {
  _$ChatTransferStateCopyWithImpl(this._self, this._then);

  final ChatTransferState _self;
  final $Res Function(ChatTransferState) _then;

/// Create a copy of ChatTransferState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? requests = null,Object? monitoredConversations = null,Object? selectedTargetUser = freezed,Object? currentUserId = null,Object? errorMessage = freezed,Object? successMessage = freezed,Object? newlyReceivedRequest = freezed,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ChatTransferStatus,requests: null == requests ? _self.requests : requests // ignore: cast_nullable_to_non_nullable
as List<ChatViewRequestModel>,monitoredConversations: null == monitoredConversations ? _self.monitoredConversations : monitoredConversations // ignore: cast_nullable_to_non_nullable
as List<ChatModel>,selectedTargetUser: freezed == selectedTargetUser ? _self.selectedTargetUser : selectedTargetUser // ignore: cast_nullable_to_non_nullable
as ChatViewUserModel?,currentUserId: null == currentUserId ? _self.currentUserId : currentUserId // ignore: cast_nullable_to_non_nullable
as String,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,successMessage: freezed == successMessage ? _self.successMessage : successMessage // ignore: cast_nullable_to_non_nullable
as String?,newlyReceivedRequest: freezed == newlyReceivedRequest ? _self.newlyReceivedRequest : newlyReceivedRequest // ignore: cast_nullable_to_non_nullable
as ChatViewRequestModel?,
  ));
}
/// Create a copy of ChatTransferState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatViewUserModelCopyWith<$Res>? get selectedTargetUser {
    if (_self.selectedTargetUser == null) {
    return null;
  }

  return $ChatViewUserModelCopyWith<$Res>(_self.selectedTargetUser!, (value) {
    return _then(_self.copyWith(selectedTargetUser: value));
  });
}/// Create a copy of ChatTransferState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatViewRequestModelCopyWith<$Res>? get newlyReceivedRequest {
    if (_self.newlyReceivedRequest == null) {
    return null;
  }

  return $ChatViewRequestModelCopyWith<$Res>(_self.newlyReceivedRequest!, (value) {
    return _then(_self.copyWith(newlyReceivedRequest: value));
  });
}
}


/// Adds pattern-matching-related methods to [ChatTransferState].
extension ChatTransferStatePatterns on ChatTransferState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatTransferState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatTransferState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatTransferState value)  $default,){
final _that = this;
switch (_that) {
case _ChatTransferState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatTransferState value)?  $default,){
final _that = this;
switch (_that) {
case _ChatTransferState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ChatTransferStatus status,  List<ChatViewRequestModel> requests,  List<ChatModel> monitoredConversations,  ChatViewUserModel? selectedTargetUser,  String currentUserId,  String? errorMessage,  String? successMessage,  ChatViewRequestModel? newlyReceivedRequest)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatTransferState() when $default != null:
return $default(_that.status,_that.requests,_that.monitoredConversations,_that.selectedTargetUser,_that.currentUserId,_that.errorMessage,_that.successMessage,_that.newlyReceivedRequest);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ChatTransferStatus status,  List<ChatViewRequestModel> requests,  List<ChatModel> monitoredConversations,  ChatViewUserModel? selectedTargetUser,  String currentUserId,  String? errorMessage,  String? successMessage,  ChatViewRequestModel? newlyReceivedRequest)  $default,) {final _that = this;
switch (_that) {
case _ChatTransferState():
return $default(_that.status,_that.requests,_that.monitoredConversations,_that.selectedTargetUser,_that.currentUserId,_that.errorMessage,_that.successMessage,_that.newlyReceivedRequest);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ChatTransferStatus status,  List<ChatViewRequestModel> requests,  List<ChatModel> monitoredConversations,  ChatViewUserModel? selectedTargetUser,  String currentUserId,  String? errorMessage,  String? successMessage,  ChatViewRequestModel? newlyReceivedRequest)?  $default,) {final _that = this;
switch (_that) {
case _ChatTransferState() when $default != null:
return $default(_that.status,_that.requests,_that.monitoredConversations,_that.selectedTargetUser,_that.currentUserId,_that.errorMessage,_that.successMessage,_that.newlyReceivedRequest);case _:
  return null;

}
}

}

/// @nodoc


class _ChatTransferState extends ChatTransferState {
  const _ChatTransferState({this.status = ChatTransferStatus.initial, final  List<ChatViewRequestModel> requests = const <ChatViewRequestModel>[], final  List<ChatModel> monitoredConversations = const <ChatModel>[], this.selectedTargetUser, this.currentUserId = '', this.errorMessage, this.successMessage, this.newlyReceivedRequest}): _requests = requests,_monitoredConversations = monitoredConversations,super._();
  

@override@JsonKey() final  ChatTransferStatus status;
 final  List<ChatViewRequestModel> _requests;
@override@JsonKey() List<ChatViewRequestModel> get requests {
  if (_requests is EqualUnmodifiableListView) return _requests;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_requests);
}

 final  List<ChatModel> _monitoredConversations;
@override@JsonKey() List<ChatModel> get monitoredConversations {
  if (_monitoredConversations is EqualUnmodifiableListView) return _monitoredConversations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_monitoredConversations);
}

@override final  ChatViewUserModel? selectedTargetUser;
@override@JsonKey() final  String currentUserId;
@override final  String? errorMessage;
@override final  String? successMessage;
@override final  ChatViewRequestModel? newlyReceivedRequest;

/// Create a copy of ChatTransferState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatTransferStateCopyWith<_ChatTransferState> get copyWith => __$ChatTransferStateCopyWithImpl<_ChatTransferState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatTransferState&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._requests, _requests)&&const DeepCollectionEquality().equals(other._monitoredConversations, _monitoredConversations)&&(identical(other.selectedTargetUser, selectedTargetUser) || other.selectedTargetUser == selectedTargetUser)&&(identical(other.currentUserId, currentUserId) || other.currentUserId == currentUserId)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.successMessage, successMessage) || other.successMessage == successMessage)&&(identical(other.newlyReceivedRequest, newlyReceivedRequest) || other.newlyReceivedRequest == newlyReceivedRequest));
}


@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(_requests),const DeepCollectionEquality().hash(_monitoredConversations),selectedTargetUser,currentUserId,errorMessage,successMessage,newlyReceivedRequest);

@override
String toString() {
  return 'ChatTransferState(status: $status, requests: $requests, monitoredConversations: $monitoredConversations, selectedTargetUser: $selectedTargetUser, currentUserId: $currentUserId, errorMessage: $errorMessage, successMessage: $successMessage, newlyReceivedRequest: $newlyReceivedRequest)';
}


}

/// @nodoc
abstract mixin class _$ChatTransferStateCopyWith<$Res> implements $ChatTransferStateCopyWith<$Res> {
  factory _$ChatTransferStateCopyWith(_ChatTransferState value, $Res Function(_ChatTransferState) _then) = __$ChatTransferStateCopyWithImpl;
@override @useResult
$Res call({
 ChatTransferStatus status, List<ChatViewRequestModel> requests, List<ChatModel> monitoredConversations, ChatViewUserModel? selectedTargetUser, String currentUserId, String? errorMessage, String? successMessage, ChatViewRequestModel? newlyReceivedRequest
});


@override $ChatViewUserModelCopyWith<$Res>? get selectedTargetUser;@override $ChatViewRequestModelCopyWith<$Res>? get newlyReceivedRequest;

}
/// @nodoc
class __$ChatTransferStateCopyWithImpl<$Res>
    implements _$ChatTransferStateCopyWith<$Res> {
  __$ChatTransferStateCopyWithImpl(this._self, this._then);

  final _ChatTransferState _self;
  final $Res Function(_ChatTransferState) _then;

/// Create a copy of ChatTransferState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? requests = null,Object? monitoredConversations = null,Object? selectedTargetUser = freezed,Object? currentUserId = null,Object? errorMessage = freezed,Object? successMessage = freezed,Object? newlyReceivedRequest = freezed,}) {
  return _then(_ChatTransferState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ChatTransferStatus,requests: null == requests ? _self._requests : requests // ignore: cast_nullable_to_non_nullable
as List<ChatViewRequestModel>,monitoredConversations: null == monitoredConversations ? _self._monitoredConversations : monitoredConversations // ignore: cast_nullable_to_non_nullable
as List<ChatModel>,selectedTargetUser: freezed == selectedTargetUser ? _self.selectedTargetUser : selectedTargetUser // ignore: cast_nullable_to_non_nullable
as ChatViewUserModel?,currentUserId: null == currentUserId ? _self.currentUserId : currentUserId // ignore: cast_nullable_to_non_nullable
as String,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,successMessage: freezed == successMessage ? _self.successMessage : successMessage // ignore: cast_nullable_to_non_nullable
as String?,newlyReceivedRequest: freezed == newlyReceivedRequest ? _self.newlyReceivedRequest : newlyReceivedRequest // ignore: cast_nullable_to_non_nullable
as ChatViewRequestModel?,
  ));
}

/// Create a copy of ChatTransferState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatViewUserModelCopyWith<$Res>? get selectedTargetUser {
    if (_self.selectedTargetUser == null) {
    return null;
  }

  return $ChatViewUserModelCopyWith<$Res>(_self.selectedTargetUser!, (value) {
    return _then(_self.copyWith(selectedTargetUser: value));
  });
}/// Create a copy of ChatTransferState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatViewRequestModelCopyWith<$Res>? get newlyReceivedRequest {
    if (_self.newlyReceivedRequest == null) {
    return null;
  }

  return $ChatViewRequestModelCopyWith<$Res>(_self.newlyReceivedRequest!, (value) {
    return _then(_self.copyWith(newlyReceivedRequest: value));
  });
}
}

// dart format on
