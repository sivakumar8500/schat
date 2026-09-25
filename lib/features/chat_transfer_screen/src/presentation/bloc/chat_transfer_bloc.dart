import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:schat/core/storage/storage_service.dart';
import 'package:schat/features/chat_socket_screen/src/domain/chat_socket_repository.dart';
import 'package:schat/features/chat_transfer_screen/src/domain/models/chat_view_request_model.dart';
import 'package:schat/features/chat_transfer_screen/src/domain/usecases/get_chat_view_requests_usecase.dart';
import 'package:schat/features/chat_transfer_screen/src/domain/usecases/get_target_conversations_usecase.dart';
import 'package:schat/features/chat_transfer_screen/src/domain/usecases/respond_chat_view_request_usecase.dart';
import 'package:schat/features/chat_transfer_screen/src/domain/usecases/revoke_chat_view_request_usecase.dart';
import 'package:schat/features/chat_transfer_screen/src/domain/usecases/send_chat_view_request_usecase.dart';
import 'chat_transfer_event.dart';
import 'chat_transfer_state.dart';

@injectable
class ChatTransferBloc extends Bloc<ChatTransferEvent, ChatTransferState> {
  final StorageService _storageService;
  final SendChatViewRequestUseCase _sendChatViewRequestUseCase;
  final GetChatViewRequestsUseCase _getChatViewRequestsUseCase;
  final RespondChatViewRequestUseCase _respondChatViewRequestUseCase;
  final RevokeChatViewRequestUseCase _revokeChatViewRequestUseCase;
  final GetTargetConversationsUseCase _getTargetConversationsUseCase;
  final ChatSocketRepository _chatSocketRepository;

  StreamSubscription? _socketSubscription;

  ChatTransferBloc(
    this._storageService,
    this._sendChatViewRequestUseCase,
    this._getChatViewRequestsUseCase,
    this._respondChatViewRequestUseCase,
    this._revokeChatViewRequestUseCase,
    this._getTargetConversationsUseCase,
    this._chatSocketRepository,
  ) : super(const ChatTransferState()) {
    on<LoadChatTransferData>(_onLoadChatTransferData);
    on<SendChatTransferRequest>(_onSendChatTransferRequest);
    on<RespondChatTransferRequest>(_onRespondChatTransferRequest);
    on<RevokeChatTransferRequest>(_onRevokeChatTransferRequest);
    on<LoadTargetConversations>(_onLoadTargetConversations);
    on<SocketChatViewRequestReceived>(_onSocketChatViewRequestReceived);
    on<SocketChatViewRequestUpdated>(_onSocketChatViewRequestUpdated);
    on<ClearTransferMessages>(_onClearTransferMessages);

    _initSocketListener();
  }

  void _initSocketListener() {
    _socketSubscription?.cancel();
    _socketSubscription = _chatSocketRepository.onMessage.listen((data) {
      if (data is Map<String, dynamic>) {
        final type = data['type']?.toString();
        if (type == 'chat_view_request_received') {
          if (data['request'] is Map) {
            final req = ChatViewRequestModel.fromJson(Map<String, dynamic>.from(data['request'] as Map));
            add(SocketChatViewRequestReceived(req));
          }
        } else if (type == 'chat_view_request_accepted' ||
            type == 'chat_view_request_rejected' ||
            type == 'chat_view_request_revoked') {
          if (data['request'] is Map) {
            final req = ChatViewRequestModel.fromJson(Map<String, dynamic>.from(data['request'] as Map));
            add(SocketChatViewRequestUpdated(req));
          } else {
            add(const LoadChatTransferData());
          }
        } else if (type == 'new_message' && data['is_monitored'] == true) {
          final monitoredUserId = data['monitored_user_id']?.toString();
          if (monitoredUserId != null && state.selectedTargetUser?.id == monitoredUserId) {
            add(LoadTargetConversations(targetUserId: monitoredUserId));
          }
        }
      }
    });
  }

  Future<void> _onLoadChatTransferData(
    LoadChatTransferData event,
    Emitter<ChatTransferState> emit,
  ) async {
    final currentUserId = _storageService.getUserId() ?? '';
    emit(state.copyWith(
      status: ChatTransferStatus.loading,
      currentUserId: currentUserId,
      errorMessage: null,
      successMessage: null,
    ));

    final result = await _getChatViewRequestsUseCase.execute();
    result.when(
      success: (requests) {
        emit(state.copyWith(
          status: ChatTransferStatus.success,
          requests: requests,
          currentUserId: currentUserId,
        ));
      },
      failure: (message, statusCode) {
        emit(state.copyWith(
          status: ChatTransferStatus.failure,
          errorMessage: message,
          currentUserId: currentUserId,
        ));
      },
    );
  }

  Future<void> _onSendChatTransferRequest(
    SendChatTransferRequest event,
    Emitter<ChatTransferState> emit,
  ) async {
    emit(state.copyWith(
      status: ChatTransferStatus.loading,
      errorMessage: null,
      successMessage: null,
    ));

    final result = await _sendChatViewRequestUseCase.execute(receiverId: event.receiverId);
    result.when(
      success: (newRequest) {
        final updatedList = [
          newRequest,
          ...state.requests.where((r) => r.id != newRequest.id),
        ];
        emit(state.copyWith(
          status: ChatTransferStatus.success,
          requests: updatedList,
          successMessage: 'Chat view request sent successfully.',
        ));
      },
      failure: (message, statusCode) {
        emit(state.copyWith(
          status: ChatTransferStatus.failure,
          errorMessage: message,
        ));
      },
    );
  }

  Future<void> _onRespondChatTransferRequest(
    RespondChatTransferRequest event,
    Emitter<ChatTransferState> emit,
  ) async {
    emit(state.copyWith(
      status: ChatTransferStatus.loading,
      errorMessage: null,
      successMessage: null,
    ));

    final result = await _respondChatViewRequestUseCase.execute(
      requestId: event.requestId,
      accept: event.accept,
    );

    result.when(
      success: (updatedRequest) {
        final updatedList = state.requests.map((r) {
          return r.id == updatedRequest.id ? updatedRequest : r;
        }).toList();

        emit(state.copyWith(
          status: ChatTransferStatus.success,
          requests: updatedList,
          newlyReceivedRequest: null,
          successMessage: event.accept ? 'Request accepted.' : 'Request rejected.',
        ));
      },
      failure: (message, statusCode) {
        emit(state.copyWith(
          status: ChatTransferStatus.failure,
          errorMessage: message,
        ));
      },
    );
  }

  Future<void> _onRevokeChatTransferRequest(
    RevokeChatTransferRequest event,
    Emitter<ChatTransferState> emit,
  ) async {
    emit(state.copyWith(
      status: ChatTransferStatus.loading,
      errorMessage: null,
      successMessage: null,
    ));

    final result = await _revokeChatViewRequestUseCase.execute(requestId: event.requestId);
    result.when(
      success: (revokedRequest) {
        final updatedList = state.requests.map((r) {
          return r.id == revokedRequest.id ? revokedRequest : r;
        }).toList();

        emit(state.copyWith(
          status: ChatTransferStatus.success,
          requests: updatedList,
          successMessage: 'Access revoked successfully.',
        ));
      },
      failure: (message, statusCode) {
        emit(state.copyWith(
          status: ChatTransferStatus.failure,
          errorMessage: message,
        ));
      },
    );
  }

  Future<void> _onLoadTargetConversations(
    LoadTargetConversations event,
    Emitter<ChatTransferState> emit,
  ) async {
    emit(state.copyWith(
      status: ChatTransferStatus.loading,
      selectedTargetUser: event.targetUser ?? state.selectedTargetUser,
      errorMessage: null,
    ));

    final result = await _getTargetConversationsUseCase.execute(targetUserId: event.targetUserId);
    result.when(
      success: (conversations) {
        emit(state.copyWith(
          status: ChatTransferStatus.success,
          monitoredConversations: conversations,
        ));
      },
      failure: (message, statusCode) {
        emit(state.copyWith(
          status: ChatTransferStatus.failure,
          errorMessage: message,
        ));
      },
    );
  }

  void _onSocketChatViewRequestReceived(
    SocketChatViewRequestReceived event,
    Emitter<ChatTransferState> emit,
  ) {
    final updatedList = [
      event.request,
      ...state.requests.where((r) => r.id != event.request.id),
    ];
    emit(state.copyWith(
      requests: updatedList,
      newlyReceivedRequest: event.request,
    ));
  }

  void _onSocketChatViewRequestUpdated(
    SocketChatViewRequestUpdated event,
    Emitter<ChatTransferState> emit,
  ) {
    final updatedList = state.requests.map((r) {
      return r.id == event.request.id ? event.request : r;
    }).toList();
    emit(state.copyWith(requests: updatedList));
  }

  void _onClearTransferMessages(
    ClearTransferMessages event,
    Emitter<ChatTransferState> emit,
  ) {
    emit(state.copyWith(
      errorMessage: null,
      successMessage: null,
      newlyReceivedRequest: null,
    ));
  }

  @override
  Future<void> close() {
    _socketSubscription?.cancel();
    return super.close();
  }
}
