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
    emit(const AuthLoading());
    final cleanPhone = event.phoneNumber.trim();
    if (cleanPhone.length != 10) {
      emit(const AuthFailure(errorMessage: 'Please enter a valid 10-digit number.'));
      return;
    }
    final firstChar = cleanPhone[0];
    if (!['6', '7', '8', '9'].contains(firstChar)) {
      emit(const AuthFailure(errorMessage: 'Number must start with 6, 7, 8, or 9.'));
      return;
    }
    
    final fullMobile = '${event.countryCode}$cleanPhone';
    try {
      final success = await _authRepository.sendOtp(fullMobile);
      if (success) {
        emit(OtpSent(mobile: fullMobile));
      } else {
        emit(const AuthFailure(errorMessage: 'Failed to send OTP. Please try again.'));
      }
    } catch (e) {
      emit(AuthFailure(errorMessage: e.toString()));
    }
  }

  Future<void> _onVerifyOtp(VerifyOtpEvent event, Emitter<AuthState> emit) async {
    final currentState = state;
    if (currentState is! OtpSent) {
      emit(const AuthFailure(errorMessage: 'Session expired. Please request a new OTP.'));
      return;
    }

    emit(const AuthLoading());
    final otp = event.otpCode.trim();
    if (otp.length != 6 || int.tryParse(otp) == null) {
      emit(const AuthFailure(errorMessage: 'OTP must be 6 digits.'));
      emit(OtpSent(mobile: currentState.mobile));
      return;
    }

    try {
      final success = await _authRepository.verifyOtp(currentState.mobile, otp);
      if (success) {
        emit(const AuthSuccess());
      } else {
        emit(const AuthFailure(errorMessage: 'Invalid OTP.'));
        emit(OtpSent(mobile: currentState.mobile));
      }
    } catch (e) {
      emit(AuthFailure(errorMessage: e.toString()));
      emit(OtpSent(mobile: currentState.mobile));
    }
  }
}
