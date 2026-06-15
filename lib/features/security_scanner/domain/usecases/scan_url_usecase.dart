import 'package:injectable/injectable.dart';
import '../entities/security_report.dart';
import '../repositories/security_repository.dart';

@lazySingleton
class ScanUrlUseCase {
  final SecurityRepository repository;

  ScanUrlUseCase(this.repository);

  Future<SecurityReport> call(String url) async {
    return await repository.scanUrl(url);
  }
}
