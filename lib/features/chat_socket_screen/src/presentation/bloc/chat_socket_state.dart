abstract class ChatSocketState {
  const ChatSocketState();
}

class ChatSocketInitial extends ChatSocketState {}

class ChatSocketConnecting extends ChatSocketState {}

class ChatSocketConnected extends ChatSocketState {}

class ChatSocketDisconnected extends ChatSocketState {}

class ChatSocketError extends ChatSocketState {
  final String message;
  const ChatSocketError(this.message);
}
