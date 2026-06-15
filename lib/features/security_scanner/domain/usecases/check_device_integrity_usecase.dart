import 'package:injectable/injectable.dart';
import '../repositories/security_repository.dart';

@lazySingleton
class CheckDeviceIntegrityUseCase {
  final SecurityRepository repository;

  CheckDeviceIntegrityUseCase(this.repository);

  Future<bool> call() async {
    return await repository.checkDeviceIntegrity();
  }
}
