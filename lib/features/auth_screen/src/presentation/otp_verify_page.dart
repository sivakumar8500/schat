import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode;
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
import 'package:schat/core/notifications/push_notification_service.dart';
import 'package:schat/core/storage/storage_service.dart';
import 'package:schat/injection.dart';
import 'package:schat/common/widgets/auth_hero_header.dart';
import 'package:schat/common/widgets/mesh_background.dart';
import 'package:schat/common/widgets/primary_action_button.dart';
import 'package:sms_autofill/sms_autofill.dart';

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

class _OtpVerifyPageState extends State<OtpVerifyPage>
    with CodeAutoFill, WidgetsBindingObserver {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  Timer? _countdownTimer;
  int _secondsRemaining = 120;
  bool _isAutoVerifying = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startCountdown();
    _setupFocusNodes();
    _initSmsListener();
    _checkTestNumberAutoFill();
  }

  void _checkTestNumberAutoFill() {
    final clean = widget.mobileNumber.replaceAll(RegExp(r'\D'), '');
    if (clean.endsWith('9900990099')) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fillAndVerifyOtp('112233');
      });
    }
  }

  void _initSmsListener() async {
    try {
      if (widget.autoFill) {
        listenForCode();
      }
      if (kDebugMode) {
        final signature = await SmsAutoFill().getAppSignature;
        debugPrint("OTP AutoFill Signature: $signature");
      }
    } catch (e) {
      debugPrint("OTP AutoFill init error: $e");
    }
    _checkClipboardForOtp();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkClipboardForOtp();
    }
  }

  Future<void> _checkClipboardForOtp() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data?.text != null && mounted) {
        final text = data!.text!.trim();
        final match = RegExp(r'\b\d{6}\b').firstMatch(text);
        if (match != null) {
          final otp = match.group(0)!;
          final isAllEmpty = _controllers.every((c) => c.text.isEmpty);
          if (isAllEmpty) {
            _fillAndVerifyOtp(otp);
          }
        }
      }
    } catch (e) {
      debugPrint("Clipboard OTP check error: $e");
    }
  }

  @override
  void codeUpdated() {
    if (code != null && code!.isNotEmpty) {
      final match = RegExp(r'\d{6}').firstMatch(code!);
      final otp = match != null ? match.group(0) : code!.replaceAll(RegExp(r'\D'), '');
      if (otp != null && otp.length == 6) {
        debugPrint("OTP Auto-filled from SMS: $otp");
        _fillAndVerifyOtp(otp);
      }
    }
  }

  void _fillAndVerifyOtp(String otp) {
    if (!mounted || otp.length != 6) return;
    for (int i = 0; i < 6; i++) {
      _controllers[i].text = otp[i];
    }
    for (var node in _focusNodes) {
      node.unfocus();
    }
    setState(() {});
    _verifyOtp(context);
  }

  void _setupFocusNodes() {
    for (int i = 0; i < 6; i++) {
      _focusNodes[i].addListener(() {
        if (mounted) setState(() {});
      });
      _focusNodes[i].onKeyEvent = (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.backspace) {
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
    _secondsRemaining = 120;
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
    WidgetsBinding.instance.removeObserver(this);
    cancel();
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
    if (_isAutoVerifying) return;
    String otp = _controllers.map((c) => c.text).join();
    
    if (otp.length < 6) {
      context.showErrorNotification('Please enter the complete 6-digit OTP.');
      return;
    }

    _isAutoVerifying = true;
    final deviceId = getIt<StorageService>().getOrGenerateDeviceId();
    context.read<AuthBloc>().add(
      VerifyOtpEvent(otpCode: otp, deviceId: deviceId),
    );
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

    final cleanValue = value.replaceAll(RegExp(r'\D'), '');
    if (cleanValue.isEmpty) {
      _controllers[index].text = '';
      setState(() {});
      return;
    }

    if (cleanValue.length >= 6) {
      _fillAndVerifyOtp(cleanValue.substring(0, 6));
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
      setState(() {});
      if (_isOtpComplete) {
        _verifyOtp(context);
      }
      return;
    }

    _controllers[index].text = cleanValue;
    if (index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else {
      _focusNodes[index].unfocus();
    }
    setState(() {});
    if (_isOtpComplete) {
      _verifyOtp(context);
    }
  }

  void _clearOtpFields() {
    _isAutoVerifying = false;
    for (var controller in _controllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
    setState(() {});
  }

  bool get _isOtpComplete => _controllers.every((c) => c.text.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    final isDark = context.colors.isDark;
    final fieldBgColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFF3F4F6);

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthSuccess) {
          getIt<PushNotificationService>().registerToken();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ProfilePage()),
          );
        } else if (state is AuthFailure) {
          context.showErrorNotification(state.errorMessage);
          _clearOtpFields();
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        final isEnabled = _isOtpComplete && !isLoading;

        return Scaffold(
          backgroundColor: context.colors.scaffoldBackground,
          resizeToAvoidBottomInset: true,
          body: MeshBackground(
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 26.0),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CommonSpaces.h16,
                            // Top Navigation & Back Button
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                InkWell(
                                  onTap: () => Navigator.pop(context),
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.08)
                                          : Colors.black.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isDark
                                            ? Colors.white.withValues(alpha: 0.12)
                                            : const Color(0xFFE5E7EB),
                                        width: 1,
                                      ),
                                    ),
                                    child: Icon(
                                      CommonIcons.arrowBack,
                                      color: context.colors.textPrimary,
                                      size: 18,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: context.colors.primary
                                        .withValues(alpha: isDark ? 0.15 : 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: context.colors.primary
                                          .withValues(alpha: isDark ? 0.35 : 0.25),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: Image.asset(
                                          CommonIcons.logo,
                                          width: 18,
                                          height: 18,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      CommonSpaces.w8,
                                      Text(
                                        'VERIFICATION',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.0,
                                          color: context.colors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const Spacer(flex: 2),

                            // Brand Hero with concentric glowing rings and S-CHAT logo
                            const AuthHeroHeader(),

                            const Spacer(flex: 3),

                            // Headline
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: "Verify ",
                                    style: context.h1.copyWith(
                                      fontSize: 34,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.5,
                                      color: context.colors.textPrimary,
                                    ),
                                  ),
                                  TextSpan(
                                    text: "your ",
                                    style: context.h1Italic.copyWith(
                                      fontSize: 34,
                                      fontWeight: FontWeight.w900,
                                      fontStyle: FontStyle.italic,
                                      color: context.colors.primary,
                                    ),
                                  ),
                                  TextSpan(
                                    text: "code.",
                                    style: context.h1.copyWith(
                                      fontSize: 34,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.5,
                                      color: context.colors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            CommonSpaces.h8,
                            Text(
                              "We've sent a 6-digit verification code to +91 ${widget.mobileNumber}",
                              style: context.bodyMedium.copyWith(
                                color: context.colors.textSecondary,
                                fontSize: 14.5,
                                height: 1.35,
                              ),
                            ),
                            CommonSpaces.h24,

                            // Code Label
                            Text(
                              'Verification Code',
                              style: context.titleSmall.copyWith(
                                color: context.colors.textSecondary,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                            CommonSpaces.h10,

                            // 6 OTP Digit Boxes
                            AutofillGroup(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: List.generate(6, (index) {
                                  final controller = _controllers[index];
                                  final isFilled = controller.text.isNotEmpty;
                                  final hasFocus = _focusNodes[index].hasFocus;
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 48,
                                    height: 58,
                                    decoration: BoxDecoration(
                                      color: fieldBgColor,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: hasFocus
                                            ? context.colors.primary
                                            : (isFilled
                                                ? context.colors.primary
                                                : (isDark
                                                    ? Colors.white
                                                        .withValues(alpha: 0.12)
                                                    : context.colors.primary.withValues(alpha: 0.25))),
                                        width: hasFocus ? 2 : 1.2,
                                      ),
                                      boxShadow: (hasFocus || isFilled)
                                          ? [
                                              BoxShadow(
                                                color: context.colors.primary
                                                    .withValues(alpha: 0.2),
                                                blurRadius: 10,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : [
                                              BoxShadow(
                                                color: Colors.black.withValues(
                                                    alpha: isDark ? 0.2 : 0.03),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                    ),
                                    child: Center(
                                      child: TextField(
                                        controller: controller,
                                        focusNode: _focusNodes[index],
                                        autofocus: index == 0,
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.center,
                                        style: context.titleLarge.copyWith(
                                          fontSize: 24,
                                          color: (isFilled || hasFocus)
                                              ? context.colors.primary
                                              : context.colors.textPrimary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        autofillHints: const [
                                          AutofillHints.oneTimeCode,
                                        ],
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly,
                                        ],
                                        decoration: InputDecoration(
                                          counterText: '',
                                          border: InputBorder.none,
                                          hintText: isFilled ? '' : '·',
                                          hintStyle: context.titleLarge.copyWith(
                                            color: context.colors.textSecondary
                                                .withValues(alpha: 0.3),
                                            fontSize: 26,
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
                            CommonSpaces.h16,

                            // Resend Code / Countdown Timer
                            Row(
                              children: [
                                Icon(
                                  CommonIcons.history,
                                  size: 16,
                                  color: context.colors.textSecondary,
                                ),
                                CommonSpaces.w6,
                                _secondsRemaining > 0
                                    ? Text(
                                        'Resend code in: ${(_secondsRemaining ~/ 60).toString().padLeft(2, '0')}:${(_secondsRemaining % 60).toString().padLeft(2, '0')}',
                                        style: context.bodyMedium.copyWith(
                                          color: context.colors.textSecondary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13.5,
                                        ),
                                      )
                                    : InkWell(
                                        onTap: () async {
                                          String? signature;
                                          try {
                                            signature = await SmsAutoFill()
                                                .getAppSignature;
                                          } catch (_) {}
                                          if (context.mounted) {
                                            context.read<AuthBloc>().add(
                                              SendOtpEvent(
                                                phoneNumber: widget.mobileNumber,
                                                appSignature: signature,
                                              ),
                                            );
                                            _startCountdown();
                                            listenForCode();
                                            _checkTestNumberAutoFill();
                                          }
                                        },
                                        child: Text(
                                          'Resend Code',
                                          style: context.bodyMedium.copyWith(
                                            color: context.colors.primary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                              ],
                            ),

                            CommonSpaces.h24,

                            // Continue Button
                            PrimaryActionButton(
                              title: 'Continue',
                              isLoading: isLoading,
                              onPressed: isEnabled ? () => _verifyOtp(context) : null,
                            ),
                            CommonSpaces.h24,
                            CommonSpaces.h16,
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
