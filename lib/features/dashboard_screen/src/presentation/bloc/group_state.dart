import 'package:schat/features/dashboard_screen/src/domain/models/chat_model.dart';

abstract class GroupState {
  const GroupState();
}

class GroupInitial extends GroupState {
  const GroupInitial();
}

class GroupLoading extends GroupState {
  const GroupLoading();
}

class GroupSuccess extends GroupState {
  final ChatModel chat;
  const GroupSuccess(this.chat);
}

class GroupError extends GroupState {
  final String message;
  const GroupError(this.message);
}
