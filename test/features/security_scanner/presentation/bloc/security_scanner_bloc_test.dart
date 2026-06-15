import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:schat/features/security_scanner/domain/entities/security_report.dart';
import 'package:schat/features/security_scanner/domain/usecases/check_device_integrity_usecase.dart';
import 'package:schat/features/security_scanner/domain/usecases/scan_file_usecase.dart';
import 'package:schat/features/security_scanner/domain/usecases/scan_url_usecase.dart';
import 'package:schat/features/security_scanner/presentation/bloc/security_scanner_bloc.dart';
import 'package:schat/features/security_scanner/presentation/bloc/security_scanner_event.dart';
import 'package:schat/features/security_scanner/presentation/bloc/security_scanner_state.dart';

class MockCheckDeviceIntegrityUseCase extends Mock implements CheckDeviceIntegrityUseCase {}
class MockScanUrlUseCase extends Mock implements ScanUrlUseCase {}
class MockScanFileUseCase extends Mock implements ScanFileUseCase {}

void main() {
  late SecurityScannerBloc bloc;
  late MockCheckDeviceIntegrityUseCase mockCheckIntegrity;
  late MockScanUrlUseCase mockScanUrl;
  late MockScanFileUseCase mockScanFile;

  setUp(() {
    mockCheckIntegrity = MockCheckDeviceIntegrityUseCase();
    mockScanUrl = MockScanUrlUseCase();
    mockScanFile = MockScanFileUseCase();
    bloc = SecurityScannerBloc(mockCheckIntegrity, mockScanUrl, mockScanFile);
  });

  tearDown(() => bloc.close());

  group('SecurityScannerBloc', () {
    blocTest<SecurityScannerBloc, SecurityScannerState>(
      'emits [loading, integrityResult] when CheckIntegrity is added',
      build: () {
        when(() => mockCheckIntegrity()).thenAnswer((_) async => true);
        return bloc;
      },
      act: (bloc) => bloc.add(const SecurityScannerEvent.checkIntegrity()),
      expect: () => [
        const SecurityScannerState.loading(),
        const SecurityScannerState.integrityResult(true),
      ],
    );

    blocTest<SecurityScannerBloc, SecurityScannerState>(
      'emits [loading, scanResult] when ScanUrl is added',
      build: () {
        const report = SecurityReport(isSafe: true, riskLevel: 'LOW', message: 'Safe');
        when(() => mockScanUrl(any())).thenAnswer((_) async => report);
        return bloc;
      },
      act: (bloc) => bloc.add(const SecurityScannerEvent.scanUrl('google.com')),
      expect: () => [
        const SecurityScannerState.loading(),
        const SecurityScannerState.scanResult(SecurityReport(isSafe: true, riskLevel: 'LOW', message: 'Safe')),
      ],
    );

    blocTest<SecurityScannerBloc, SecurityScannerState>(
      'emits [loading, scanResult] when ScanFile is added',
      build: () {
        const report = SecurityReport(isSafe: true, riskLevel: 'LOW', message: 'Safe');
        when(() => mockScanFile(any())).thenAnswer((_) async => report);
        return bloc;
      },
      act: (bloc) => bloc.add(const SecurityScannerEvent.scanFile('test.txt')),
      expect: () => [
        const SecurityScannerState.loading(),
        const SecurityScannerState.scanResult(SecurityReport(isSafe: true, riskLevel: 'LOW', message: 'Safe')),
      ],
    );

    blocTest<SecurityScannerBloc, SecurityScannerState>(
      'emits [loading, error] when CheckIntegrity fails',
      build: () {
        when(() => mockCheckIntegrity()).thenThrow(Exception('Failed'));
        return bloc;
      },
      act: (bloc) => bloc.add(const SecurityScannerEvent.checkIntegrity()),
      expect: () => [
        const SecurityScannerState.loading(),
        const SecurityScannerState.error('Exception: Failed'),
      ],
    );
  });
}
