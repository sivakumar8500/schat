import 'package:schat/features/payment_screen/src/domain/models/payment_request_model.dart';

abstract class PaymentRepository {
  Future<bool> processPayment(PaymentRequestModel request);
}
