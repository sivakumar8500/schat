import 'package:injectable/injectable.dart';
import 'package:schat/features/chat_socket_screen/src/domain/chat_socket_repository.dart';

@injectable
class ConnectSocketUseCase {
  final ChatSocketRepository _repository;

  ConnectSocketUseCase(this._repository);

  void execute() {
    _repository.connect();
  }
}
