import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:schat/features/security_scanner/domain/entities/security_report.dart';
import 'package:schat/features/security_scanner/domain/repositories/security_repository.dart';
import 'package:schat/features/security_scanner/domain/usecases/check_device_integrity_usecase.dart';
import 'package:schat/features/security_scanner/domain/usecases/scan_file_usecase.dart';
import 'package:schat/features/security_scanner/domain/usecases/scan_url_usecase.dart';

class MockSecurityRepository extends Mock implements SecurityRepository {}

void main() {
  late MockSecurityRepository mockRepository;
  late CheckDeviceIntegrityUseCase checkDeviceIntegrityUseCase;
  late ScanUrlUseCase scanUrlUseCase;
  late ScanFileUseCase scanFileUseCase;

  setUp(() {
    mockRepository = MockSecurityRepository();
    checkDeviceIntegrityUseCase = CheckDeviceIntegrityUseCase(mockRepository);
    scanUrlUseCase = ScanUrlUseCase(mockRepository);
    scanFileUseCase = ScanFileUseCase(mockRepository);
  });

  group('Security UseCases', () {
    test('CheckDeviceIntegrityUseCase calls repository', () async {
      when(() => mockRepository.checkDeviceIntegrity()).thenAnswer((_) async => true);
      final result = await checkDeviceIntegrityUseCase();
      expect(result, true);
      verify(() => mockRepository.checkDeviceIntegrity()).called(1);
    });

    test('ScanUrlUseCase calls repository', () async {
      const report = SecurityReport(isSafe: true, riskLevel: 'LOW', message: 'Safe');
      when(() => mockRepository.scanUrl(any())).thenAnswer((_) async => report);
      final result = await scanUrlUseCase('test.com');
      expect(result, report);
      verify(() => mockRepository.scanUrl('test.com')).called(1);
    });

    test('ScanFileUseCase calls repository', () async {
      const report = SecurityReport(isSafe: true, riskLevel: 'LOW', message: 'Safe');
      when(() => mockRepository.scanFile(any())).thenAnswer((_) async => report);
      final result = await scanFileUseCase('test.txt');
      expect(result, report);
      verify(() => mockRepository.scanFile('test.txt')).called(1);
    });
  });
}
