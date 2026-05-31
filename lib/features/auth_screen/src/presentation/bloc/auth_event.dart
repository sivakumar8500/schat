abstract class AuthEvent {
  const AuthEvent();
}

class SendOtpEvent extends AuthEvent {
  final String phoneNumber;
  final String countryCode;

  const SendOtpEvent({required this.phoneNumber, required this.countryCode});
}

class VerifyOtpEvent extends AuthEvent {
  final String otpCode;

  const VerifyOtpEvent({required this.otpCode});
}
