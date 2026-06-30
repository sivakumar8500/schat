abstract class AuthEvent {
  const AuthEvent();
}

class SendOtpEvent extends AuthEvent {
  final String phoneNumber;
  final String? appSignature;

  const SendOtpEvent({required this.phoneNumber, this.appSignature});
}

class VerifyOtpEvent extends AuthEvent {
  final String otpCode;
  final String deviceId;

  const VerifyOtpEvent({required this.otpCode, required this.deviceId});
}
