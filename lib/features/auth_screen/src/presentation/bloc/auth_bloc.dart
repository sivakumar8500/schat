import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schat/features/auth_screen/src/domain/repositories/auth_repository.dart';
import 'package:schat/injection.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc({AuthRepository? authRepository})
    : _authRepository = authRepository ?? getIt<AuthRepository>(),
      super(const AuthInitial()) {
    on<SendOtpEvent>(_onSendOtp);
    on<VerifyOtpEvent>(_onVerifyOtp);
  }

  Future<void> _onSendOtp(SendOtpEvent event, Emitter<AuthState> emit) async {
    // Remove all non-digit characters
    String cleanPhone = event.phoneNumber.replaceAll(RegExp(r'\D'), '');

    // If it starts with 91 and has 12 digits, strip the 91
    if (cleanPhone.length == 12 && cleanPhone.startsWith('91')) {
      cleanPhone = cleanPhone.substring(2);
    }

    if (cleanPhone.length != 10 || RegExp(r'^0+$').hasMatch(cleanPhone)) {
      emit(
        AuthFailure(
          errorMessage: 'Please enter a valid 10-digit number.',
          timestamp: DateTime.now(),
        ),
      );
      return;
    }

    emit(const AuthLoading());

    final mobileToUse = cleanPhone;

    try {
      final result = await _authRepository.sendOtp(
        mobileToUse,
        appSignature: event.appSignature,
      );
      result.when(
        success: (success) {
          if (success) {
            emit(OtpSent(mobile: mobileToUse));
          } else {
            emit(AuthFailure(
              errorMessage: 'Failed to send OTP.',
              mobile: mobileToUse,
              timestamp: DateTime.now(),
            ));
          }
        },
        failure: (message, statusCode) => emit(AuthFailure(
          errorMessage: message,
          mobile: mobileToUse,
          timestamp: DateTime.now(),
        )),
      );
    } catch (e) {
      emit(AuthFailure(
        errorMessage: e.toString(),
        mobile: mobileToUse,
        timestamp: DateTime.now(),
      ));
    }
  }

  Future<void> _onVerifyOtp(
    VerifyOtpEvent event,
    Emitter<AuthState> emit,
  ) async {
    final currentState = state;
    String? mobile;
    if (currentState is OtpSent) {
      mobile = currentState.mobile;
    } else if (currentState is AuthFailure) {
      mobile = currentState.mobile;
    }

    if (mobile == null) {
      emit(
        AuthFailure(
          errorMessage: 'Session expired. Please request a new OTP.',
          timestamp: DateTime.now(),
        ),
      );
      return;
    }

    emit(const AuthLoading());
    final otp = event.otpCode.trim();
    if (otp.length != 6 || int.tryParse(otp) == null) {
      emit(AuthFailure(
        errorMessage: 'OTP must be 6 digits.',
        mobile: mobile,
        timestamp: DateTime.now(),
      ));
      return;
    }

    try {
      final result = await _authRepository.verifyOtp(
        mobile,
        otp,
        event.deviceId,
      );
      result.when(
        success: (success) {
          if (success) {
            emit(const AuthSuccess());
          } else {
            emit(AuthFailure(
              errorMessage: 'Invalid OTP.',
              mobile: mobile,
              timestamp: DateTime.now(),
            ));
          }
        },
        failure: (message, statusCode) => emit(AuthFailure(
          errorMessage: message,
          mobile: mobile,
          timestamp: DateTime.now(),
        )),
      );
    } catch (e) {
      emit(AuthFailure(
        errorMessage: e.toString(),
        mobile: mobile,
        timestamp: DateTime.now(),
      ));
    }
  }
}
