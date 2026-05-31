import 'package:flutter_test/flutter_test.dart';
import 'package:schat/features/payment_screen/src/data/repositories/payment_repository_impl.dart';
import 'package:schat/features/payment_screen/src/domain/models/payment_request_model.dart';

void main() {
  late PaymentRepositoryImpl repository;

  setUp(() {
    repository = PaymentRepositoryImpl();
  });

  group('PaymentRepositoryImpl', () {
    test('processPayment returns false for invalid data', () async {
      final request = PaymentRequestModel(
        planId: '1',
        cardholderName: 'Test',
        cardNumber: '123', // too short
        expiry: '12/24',
        cvv: '12', // too short
      );
      final result = await repository.processPayment(request);
      expect(result, isFalse);
    });

    test('processPayment returns true for valid data', () async {
      final request = PaymentRequestModel(
        planId: '1',
        cardholderName: 'Test Name',
        cardNumber: '1234567812345678', // valid length
        expiry: '12/24',
        cvv: '123', // valid length
      );
      final result = await repository.processPayment(request);
      expect(result, isTrue);
    });
  });
}
