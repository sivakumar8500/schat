import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schat/features/auth_screen/src/presentation/bloc/auth_bloc.dart';
import 'package:schat/features/auth_screen/src/presentation/bloc/auth_event.dart';
import 'package:schat/features/auth_screen/src/presentation/bloc/auth_state.dart';
import 'package:schat/features/auth_screen/src/presentation/otp_verify_page.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_icons.dart';
import 'package:schat/utils/common_spaces.dart';


class MobileEntryPage extends StatefulWidget {
  const MobileEntryPage({super.key});

  @override
  State<MobileEntryPage> createState() => _MobileEntryPageState();
}

class _MobileEntryPageState extends State<MobileEntryPage> {
  final TextEditingController _mobileController = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _mobileController.dispose();
    super.dispose();
  }

  void _sendOtp(BuildContext context) {
    final mobile = _mobileController.text.trim();
    context.read<AuthBloc>().add(SendOtpEvent(phoneNumber: mobile, countryCode: '+91'));
  }

  @override
  Widget build(BuildContext context) {
    final cardBgColor = context.colors.cardBackground;
    final fieldBgColor = context.colors.isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white;

    return BlocProvider<AuthBloc>(
      create: (context) => AuthBloc(),
      child: Builder(
        builder: (context) {
          return BlocConsumer<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is OtpSent) {
                _errorText = null;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (routeContext) => BlocProvider.value(
                      value: BlocProvider.of<AuthBloc>(context),
                      child: OtpVerifyPage(mobileNumber: state.mobile),
                    ),
                  ),
                );
              } else if (state is AuthFailure) {
                setState(() {
                  _errorText = state.errorMessage;
                });
              }
            },
            builder: (context, state) {
              final isLoading = state is AuthLoading;

              return Scaffold(
                backgroundColor: context.colors.scaffoldBackground,
                body: Column(
                  children: [
                    // Top illustration area
                    Expanded(
                      flex: 5,
                      child: Container(
                        color: context.colors.scaffoldBackground,
                        child: SafeArea(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Image.asset(
                                'assets/images/secure_chats.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Bottom card area
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: cardBgColor,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(40),
                        ),
                      ),
                      child: SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 30.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Back button
                              Align(
                                alignment: Alignment.centerLeft,
                                child: InkWell(
                                  onTap: () => Navigator.pop(context),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Icon(
                                      CommonIcons.arrowBack,
                                      color: context.colors.textPrimary,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ),
                              CommonSpaces.h16,

                              // Header title
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    "Let's ",
                                    style: context.h1.copyWith(fontSize: 36),
                                  ),
                                  Text(
                                    "get ",
                                    style: context.h1Italic.copyWith(fontSize: 34),
                                  ),
                                  Text(
                                    "you in.",
                                    style: context.h1.copyWith(fontSize: 36),
                                  ),
                                ],
                              ),
                              CommonSpaces.h24,

                              // Phone number section label
                              Text(
                                'Phone number',
                                style: context.titleSmall,
                              ),
                              CommonSpaces.h12,

                              // Input Row (Dropdown + TextField)
                              Row(
                                children: [
                                  // Country Code Selection
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                    decoration: BoxDecoration(
                                      color: fieldBgColor,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text('🇮🇳', style: TextStyle(fontSize: 22)),
                                        CommonSpaces.w8,
                                        Text(
                                          '+91',
                                          style: context.titleSmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  CommonSpaces.w12,

                                  // Mobile Number Input Field
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: fieldBgColor,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: TextField(
                                        controller: _mobileController,
                                        keyboardType: TextInputType.phone,
                                        maxLength: 10,
                                        onChanged: (value) {
                                          if (_errorText != null) {
                                            setState(() {
                                              _errorText = null;
                                            });
                                          }
                                        },
                                        style: context.titleSmall,
                                        decoration: InputDecoration(
                                          hintText: '000 000 0000',
                                          counterText: '',
                                          hintStyle: context.bodyMedium.copyWith(
                                            color: context.colors.textHint.withValues(alpha: 0.6),
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            borderSide: BorderSide.none,
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (_errorText != null) ...[
                                CommonSpaces.h8,
                                Padding(
                                  padding: const EdgeInsets.only(left: 4.0),
                                  child: Text(
                                    _errorText!,
                                    style: context.bodySmall.copyWith(
                                      color: context.colors.error,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                              CommonSpaces.h40,

                              // Continue Button
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: isLoading ? null : () => _sendOtp(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: context.colors.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Continue',
                                        style: context.titleMedium.copyWith(
                                          color: Colors.white,
                                        ),
                                      ),
                                      CommonSpaces.w8,
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          CommonIcons.arrowForward,
                                          color: context.colors.primary,
                                          size: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              CommonSpaces.h20,

                              // Terms and privacy disclaimer
                              Center(
                                child: Text.rich(
                                  TextSpan(
                                    text: 'By continuing you agree to our\n',
                                    style: context.bodyMedium.copyWith(height: 1.4),
                                    children: [
                                      TextSpan(
                                        text: 'Terms',
                                        style: context.bodyMedium.copyWith(
                                          color: context.colors.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const TextSpan(text: ' & '),
                                      TextSpan(
                                        text: 'Privacy Policy',
                                        style: context.bodyMedium.copyWith(
                                          color: context.colors.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
