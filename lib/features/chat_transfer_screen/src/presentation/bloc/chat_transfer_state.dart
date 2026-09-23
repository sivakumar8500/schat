import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:schat/features/chat_transfer_screen/src/domain/models/chat_view_request_model.dart';
import 'package:schat/features/chat_transfer_screen/src/domain/models/chat_view_user_model.dart';
import 'package:schat/features/dashboard_screen/src/domain/models/chat_model.dart';

part 'chat_transfer_state.freezed.dart';

enum ChatTransferStatus { initial, loading, success, failure }

@freezed
abstract class ChatTransferState with _$ChatTransferState {
  const ChatTransferState._();

  const factory ChatTransferState({
    @Default(ChatTransferStatus.initial) ChatTransferStatus status,
    @Default(<ChatViewRequestModel>[]) List<ChatViewRequestModel> requests,
    @Default(<ChatModel>[]) List<ChatModel> monitoredConversations,
    ChatViewUserModel? selectedTargetUser,
    @Default('') String currentUserId,
    String? errorMessage,
    String? successMessage,
    ChatViewRequestModel? newlyReceivedRequest,
  }) = _ChatTransferState;

  List<ChatViewRequestModel> get incomingPendingRequests =>
      requests.where((r) => r.receiverId == currentUserId && r.status == 'pending').toList();

  List<ChatViewRequestModel> get outgoingPendingRequests =>
      requests.where((r) => r.senderId == currentUserId && r.status == 'pending').toList();

  List<ChatViewRequestModel> get activeMonitoredAccounts =>
      requests.where((r) => r.senderId == currentUserId && r.status == 'accepted').toList();

  List<ChatViewRequestModel> get activeViewers =>
      requests.where((r) => r.receiverId == currentUserId && r.status == 'accepted').toList();
}
