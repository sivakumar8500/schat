import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:schat/core/network/api_result.dart';
import 'package:schat/features/auth_screen/src/domain/repositories/auth_repository.dart';
import 'package:schat/features/auth_screen/src/presentation/bloc/auth_bloc.dart';
import 'package:schat/features/auth_screen/src/presentation/bloc/auth_event.dart';
import 'package:schat/features/auth_screen/src/presentation/bloc/auth_state.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late AuthBloc authBloc;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    authBloc = AuthBloc(authRepository: mockAuthRepository);
  });

  tearDown(() {
    authBloc.close();
  });

  group('SendOtpEvent', () {
    const mobile = '9030303030';

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, OtpSent] when successful',
      build: () {
        when(() => mockAuthRepository.sendOtp(mobile))
            .thenAnswer((_) async => const ApiResult.success(true));
        return authBloc;
      },
      act: (bloc) => bloc.add(const SendOtpEvent(phoneNumber: mobile)),
      expect: () => [
        const AuthLoading(),
        const OtpSent(mobile: mobile),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthFailure] when validation fails (short number)',
      build: () => authBloc,
      act: (bloc) => bloc.add(const SendOtpEvent(phoneNumber: '123')),
      expect: () => [
        const AuthFailure(errorMessage: 'Please enter a valid 10-digit number.'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthFailure] when API fails',
      build: () {
        when(() => mockAuthRepository.sendOtp(mobile))
            .thenAnswer((_) async => const ApiResult.failure('Server Error'));
        return authBloc;
      },
      act: (bloc) => bloc.add(const SendOtpEvent(phoneNumber: mobile)),
      expect: () => [
        const AuthLoading(),
        const AuthFailure(errorMessage: 'Server Error'),
      ],
    );
  });

  group('VerifyOtpEvent', () {
    const mobile = '9030303030';
    const otp = '887765';
    const deviceId = 'device123';

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthSuccess] when successful',
      build: () {
        when(() => mockAuthRepository.verifyOtp(mobile, otp, deviceId))
            .thenAnswer((_) async => const ApiResult.success(true));
        return authBloc;
      },
      seed: () => const OtpSent(mobile: mobile),
      act: (bloc) => bloc.add(const VerifyOtpEvent(otpCode: otp, deviceId: deviceId)),
      expect: () => [
        const AuthLoading(),
        const AuthSuccess(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthFailure, OtpSent] when OTP is invalid',
      build: () {
        when(() => mockAuthRepository.verifyOtp(mobile, otp, deviceId))
            .thenAnswer((_) async => const ApiResult.failure('Invalid OTP'));
        return authBloc;
      },
      seed: () => const OtpSent(mobile: mobile),
      act: (bloc) => bloc.add(const VerifyOtpEvent(otpCode: otp, deviceId: deviceId)),
      expect: () => [
        const AuthLoading(),
        const AuthFailure(errorMessage: 'Invalid OTP'),
        const OtpSent(mobile: mobile),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthFailure] when session is expired (no mobile in state)',
      build: () => authBloc,
      act: (bloc) => bloc.add(const VerifyOtpEvent(otpCode: otp, deviceId: deviceId)),
      expect: () => [
        const AuthFailure(errorMessage: 'Session expired. Please request a new OTP.'),
      ],
    );
  });
}
