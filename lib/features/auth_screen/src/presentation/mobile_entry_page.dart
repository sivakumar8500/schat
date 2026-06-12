import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schat/features/auth_screen/src/presentation/bloc/auth_bloc.dart';
import 'package:schat/features/auth_screen/src/presentation/bloc/auth_event.dart';
import 'package:schat/features/auth_screen/src/presentation/bloc/auth_state.dart';
import 'package:schat/features/auth_screen/src/presentation/otp_verify_page.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_icons.dart';
import 'package:schat/utils/common_notifications.dart';
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
    context.read<AuthBloc>().add(SendOtpEvent(phoneNumber: mobile));
  }

  @override
  Widget build(BuildContext context) {
    final fieldBgColor = Colors.white.withOpacity(0.1);

    return BlocProvider<AuthBloc>(
      create: (context) => AuthBloc(),
      child: Builder(
        builder: (context) {
          return BlocConsumer<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is OtpSent) {
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
                context.showErrorNotification(state.errorMessage);
              }
            },
            builder: (context, state) {
              final isLoading = state is AuthLoading;

              return Scaffold(
                backgroundColor: context.colors.pureBlack,
                body: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Top illustration area - Matching IntroPage exactly
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.45,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Image.asset(
                                'assets/main_bg_img.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                            // Gradient overlay to blend image into black background
                            Positioned(
                              bottom: -1,
                              left: 0,
                              right: 0,
                              height: 150,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      context.colors.pureBlack.withOpacity(0),
                                      context.colors.pureBlack,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Content Area - Unified with Background
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                          // Header title
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                "Let's ",
                                style: context.h1.copyWith(fontSize: 36, color: Colors.white),
                              ),
                              Text(
                                "get ",
                                style: context.h1Italic.copyWith(fontSize: 34, color: Colors.white),
                              ),
                              Text(
                                "you in.",
                                style: context.h1.copyWith(fontSize: 36, color: Colors.white),
                              ),
                            ],
                          ),
                          CommonSpaces.h24,

                          // Phone number section label
                          Text(
                            'Phone number',
                            style: context.titleSmall.copyWith(color: Colors.white),
                          ),
                          CommonSpaces.h12,

                          // Input Row
                          Row(
                            children: [
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
                                      style: context.titleSmall.copyWith(color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                              CommonSpaces.w12,
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
                                    style: context.titleSmall.copyWith(color: Colors.white),
                                    decoration: InputDecoration(
                                      hintText: '000 000 0000',
                                      counterText: '',
                                      hintStyle: context.bodyMedium.copyWith(
                                        color: Colors.white.withOpacity(0.4),
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
                          CommonSpaces.h40,

                          // Continue Button
                          SizedBox(
                            width: double.infinity,
                            height: 64,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : () => _sendOtp(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: context.colors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                elevation: 0,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Continue',
                                    style: context.titleMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                                  ),
                                  CommonSpaces.w8,
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                    child: Icon(CommonIcons.arrowForward, color: context.colors.primary, size: 16),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          CommonSpaces.h24,

                          // Terms
                          Center(
                            child: Text.rich(
                              TextSpan(
                                text: 'By continuing you agree to our\n',
                                style: context.bodyMedium.copyWith(color: Colors.white.withOpacity(0.5), height: 1.4),
                                children: [
                                  TextSpan(text: 'Terms', style: context.bodyMedium.copyWith(color: context.colors.primary, fontWeight: FontWeight.bold)),
                                  const TextSpan(text: ' & '),
                                  TextSpan(text: 'Privacy Policy', style: context.bodyMedium.copyWith(color: context.colors.primary, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          CommonSpaces.h40,
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
            },
          );
        },
      ),
    );
  }
}
