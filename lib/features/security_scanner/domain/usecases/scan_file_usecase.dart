import 'package:injectable/injectable.dart';
import '../entities/security_report.dart';
import '../repositories/security_repository.dart';

@lazySingleton
class ScanFileUseCase {
  final SecurityRepository repository;

  ScanFileUseCase(this.repository);

  Future<SecurityReport> call(String filePath) async {
    return await repository.scanFile(filePath);
  }
}
