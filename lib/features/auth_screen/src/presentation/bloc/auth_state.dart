import 'package:flutter/foundation.dart';

@immutable
abstract class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
  
  @override
  bool operator ==(Object other) => identical(this, other) || other is AuthInitial;
  
  @override
  int get hashCode => runtimeType.hashCode;
}

class AuthLoading extends AuthState {
  const AuthLoading();
  
  @override
  bool operator ==(Object other) => identical(this, other) || other is AuthLoading;
  
  @override
  int get hashCode => runtimeType.hashCode;
}

class OtpSent extends AuthState {
  final String mobile;
  const OtpSent({required this.mobile});
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OtpSent && runtimeType == other.runtimeType && mobile == other.mobile;

  @override
  int get hashCode => mobile.hashCode;
}

class AuthSuccess extends AuthState {
  const AuthSuccess();
  
  @override
  bool operator ==(Object other) => identical(this, other) || other is AuthSuccess;
  
  @override
  int get hashCode => runtimeType.hashCode;
}

class AuthFailure extends AuthState {
  final String errorMessage;
  final String? mobile;
  final DateTime? timestamp;
  const AuthFailure({required this.errorMessage, this.mobile, this.timestamp});
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthFailure &&
          runtimeType == other.runtimeType &&
          errorMessage == other.errorMessage &&
          mobile == other.mobile &&
          timestamp == other.timestamp;

  @override
  int get hashCode => errorMessage.hashCode ^ mobile.hashCode ^ timestamp.hashCode;
}
