import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:schat/features/security_scanner/data/repositories/security_repository_impl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('safe_device');

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        if (methodCall.method == 'isJailBroken') return false;
        if (methodCall.method == 'isRealDevice') return true;
        if (methodCall.method == 'init') return null;
        return null;
      },
    );
  });

  late SecurityRepositoryImpl repository;

  setUp(() {
    repository = SecurityRepositoryImpl();
  });

  group('SecurityRepositoryImpl', () {
    test('scanUrl returns unsafe for bit.ly links', () async {
      final report = await repository.scanUrl('https://bit.ly/suspicious');
      expect(report.isSafe, false);
      expect(report.riskLevel, 'HIGH');
    });

    test('scanUrl returns safe for google.com', () async {
      final report = await repository.scanUrl('https://google.com');
      expect(report.isSafe, true);
      expect(report.riskLevel, 'LOW');
    });

    test('scanFile returns critical for .apk files', () async {
      final report = await repository.scanFile('malicious.apk');
      expect(report.isSafe, false);
      expect(report.riskLevel, 'CRITICAL');
    });

    test('scanFile returns error for non-existent file', () async {
      final report = await repository.scanFile('non_existent.txt');
      expect(report.isSafe, false);
      expect(report.riskLevel, 'UNKNOWN');
    });

    test('checkDeviceIntegrity returns bool', () async {
      final result = await repository.checkDeviceIntegrity();
      expect(result, isA<bool>());
    });
  });
}
