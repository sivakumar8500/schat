import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schat/features/auth_screen/src/presentation/bloc/auth_bloc.dart';
import 'package:schat/features/auth_screen/src/presentation/bloc/auth_event.dart';
import 'package:schat/features/auth_screen/src/presentation/bloc/auth_state.dart';
import 'package:schat/features/profile_screen/profile_screen.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_icons.dart';
import 'package:schat/utils/common_notifications.dart';
import 'package:schat/utils/common_spaces.dart';


class OtpVerifyPage extends StatefulWidget {
  final String mobileNumber;
  final bool autoFill;
  const OtpVerifyPage({
    super.key,
    required this.mobileNumber,
    this.autoFill = true,
  });

  @override
  State<OtpVerifyPage> createState() => _OtpVerifyPageState();
}

class _OtpVerifyPageState extends State<OtpVerifyPage> {
  final List<TextEditingController> _controllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  
  Timer? _countdownTimer;
  int _secondsRemaining = 30;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    _setupFocusNodes();
  }

  void _setupFocusNodes() {
    for (int i = 0; i < 6; i++) {
      _focusNodes[i].onKeyEvent = (node, event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
          if (_controllers[i].text.isEmpty && i > 0) {
            _controllers[i - 1].clear();
            _focusNodes[i - 1].requestFocus();
            setState(() {});
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      };
    }
  }

  void _startCountdown() {
    _secondsRemaining = 30;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _countdownTimer?.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _verifyOtp(BuildContext context) {
    String otp = _controllers.map((c) => c.text).join();
    // In a real app, retrieve the actual device ID using a package like device_info_plus
    const String mockDeviceId = 'ljonhonouuoi'; 
    context.read<AuthBloc>().add(VerifyOtpEvent(otpCode: otp, deviceId: mockDeviceId));
  }

  void _handleOtpInput(String value, int index) {
    if (value.isEmpty) {
      _controllers[index].text = '';
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
      setState(() {});
      return;
    }

    if (value.length == 2 && _controllers[index].text.length == 1) {
      final oldText = _controllers[index].text;
      final newChar = value.replaceFirst(oldText, '');
      if (newChar.length == 1 && RegExp(r'^\d$').hasMatch(newChar)) {
        _controllers[index].text = newChar;
        if (index < 5) {
          _focusNodes[index + 1].requestFocus();
        } else {
          _focusNodes[index].unfocus();
        }
        setState(() {});
        return;
      }
    }

    final cleanValue = value.replaceAll(RegExp(r'\D'), '');
    if (cleanValue.isEmpty) {
      _controllers[index].text = '';
      setState(() {});
      return;
    }

    if (cleanValue.length > 1) {
      for (int i = 0; i < cleanValue.length; i++) {
        if (index + i < 6) {
          _controllers[index + i].text = cleanValue[i];
        }
      }
      final targetIndex = index + cleanValue.length;
      if (targetIndex < 6) {
        _focusNodes[targetIndex].requestFocus();
      } else {
        _focusNodes[5].unfocus();
      }
    } else {
      _controllers[index].text = cleanValue;
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final fieldBgColor = Colors.white.withOpacity(0.1);

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthSuccess) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const ProfilePage(),
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
                // Top illustration area - Matching IntroPage & MobileEntryPage
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

                // Content Area
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
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
                              color: Colors.white,
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
                          "Enter the ",
                          style: context.h1.copyWith(fontSize: 36, color: Colors.white),
                        ),
                        Text(
                          "Code",
                          style: context.h1Italic.copyWith(fontSize: 34, color: Colors.white),
                        ),
                      ],
                    ),
                    CommonSpaces.h24,

                    // Code section label
                    Text(
                      'Code',
                      style: context.titleSmall.copyWith(color: Colors.white),
                    ),
                    CommonSpaces.h12,

                    // Digit boxes row
                    AutofillGroup(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(6, (index) {
                          final controller = _controllers[index];
                          final isFilled = controller.text.isNotEmpty;

                          return Container(
                            width: 48,
                            height: 56,
                            decoration: BoxDecoration(
                              color: isFilled ? context.colors.primary : fieldBgColor,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: isFilled
                                  ? [
                                      BoxShadow(
                                        color: context.colors.primary.withOpacity(0.25),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      )
                                    ]
                                  : [],
                            ),
                            child: Center(
                              child: TextField(
                                controller: controller,
                                focusNode: _focusNodes[index],
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: isFilled ? Colors.white : Colors.white,
                                ),
                                autofillHints: const [AutofillHints.oneTimeCode],
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: InputDecoration(
                                  counterText: '',
                                  border: InputBorder.none,
                                  hintText: isFilled ? '' : '·',
                                  hintStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.3),
                                    fontSize: 24,
                                  ),
                                ),
                                onChanged: (value) {
                                  _handleOtpInput(value, index);
                                },
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    
                    CommonSpaces.h12,

                    // Resend countdown
                    Row(
                      children: [
                        Icon(
                          CommonIcons.history,
                          size: 16,
                          color: Colors.white.withOpacity(0.5),
                        ),
                        CommonSpaces.w6,
                        _secondsRemaining > 0
                            ? Text(
                                'Resend the code in: 00:${_secondsRemaining.toString().padLeft(2, '0')}',
                                style: context.bodyMedium.copyWith(
                                  color: Colors.white.withOpacity(0.7),
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            : InkWell(
                                onTap: () {
                                  context.read<AuthBloc>().add(
                                        SendOtpEvent(
                                          phoneNumber: widget.mobileNumber,
                                        ),
                                      );
                                  _startCountdown();
                                },
                                child: Text(
                                  'Resend Code',
                                  style: context.bodyMedium.copyWith(
                                    color: context.colors.primary,
                                    fontWeight: FontWeight.bold,
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
                        onPressed: isLoading ? null : () => _verifyOtp(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.colors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
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
                                fontWeight: FontWeight.w600,
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
  }
}
