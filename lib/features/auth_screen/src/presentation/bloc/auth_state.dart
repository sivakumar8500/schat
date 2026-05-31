abstract class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class OtpSent extends AuthState {
  final String mobile;
  const OtpSent({required this.mobile});
}

class AuthSuccess extends AuthState {
  const AuthSuccess();
}

class AuthFailure extends AuthState {
  final String errorMessage;
  const AuthFailure({required this.errorMessage});
}
