import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schat/common/widgets/auth_hero_header.dart';
import 'package:schat/common/widgets/mesh_background.dart';
import 'package:schat/common/widgets/primary_action_button.dart';
import 'package:schat/features/auth_screen/src/presentation/bloc/auth_bloc.dart';
import 'package:schat/features/auth_screen/src/presentation/bloc/auth_event.dart';
import 'package:schat/features/auth_screen/src/presentation/bloc/auth_state.dart';
import 'package:schat/features/auth_screen/src/presentation/otp_verify_page.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_notifications.dart';
import 'package:schat/utils/common_spaces.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:schat/injection.dart';
import 'package:schat/core/notifications/call_notification_service.dart';

class MobileEntryPage extends StatefulWidget {
  const MobileEntryPage({super.key});

  @override
  State<MobileEntryPage> createState() => _MobileEntryPageState();
}

class _MobileEntryPageState extends State<MobileEntryPage> {
  final TextEditingController _mobileController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _fetchMobileNumber();
    getIt<CallNotificationService>().registerDevice();
    _phoneFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
  }

  Future<void> _fetchMobileNumber() async {
    try {
      final phone = await SmsAutoFill().hint;
      if (phone != null && mounted) {
        String cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
        if (cleanPhone.length > 10) {
          cleanPhone = cleanPhone.substring(cleanPhone.length - 10);
        }
        _mobileController.text = cleanPhone;
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error fetching phone hint: $e');
    }
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  void _sendOtp(BuildContext context) async {
    final mobile = _mobileController.text.trim();
    
    if (mobile.isEmpty) {
      context.showErrorNotification('Please enter your mobile number.');
      return;
    }
    
    if (mobile.length != 10) {
      context.showErrorNotification('Please enter a valid 10-digit number.');
      return;
    }

    final firstDigit = int.tryParse(mobile[0]);
    if (firstDigit == null || firstDigit < 6) {
      context.showErrorNotification('Mobile number must start with 6, 7, 8, or 9.');
      return;
    }

    if (RegExp(r'^0+$').hasMatch(mobile)) {
      context.showErrorNotification('Please enter a valid mobile number.');
      return;
    }

    final signature = await SmsAutoFill().getAppSignature;
    if (context.mounted) {
      context.read<AuthBloc>().add(
        SendOtpEvent(phoneNumber: mobile, appSignature: signature),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.colors.isDark;
    final inputBgColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFF3F4F6);

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
                backgroundColor: context.colors.scaffoldBackground,
                body: MeshBackground(
                  child: SafeArea(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: IntrinsicHeight(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Spacer(flex: 2),

                                  // Brand Hero with concentric glowing rings, floating dots, and S-CHAT
                                  const AuthHeroHeader(),

                                  const Spacer(flex: 3),

                                  // Headline
                                  Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: "Let's ",
                                          style: context.h1.copyWith(
                                            fontSize: 34,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: -0.5,
                                            color: context.colors.textPrimary,
                                          ),
                                        ),
                                        TextSpan(
                                          text: "get ",
                                          style: context.h1Italic.copyWith(
                                            fontSize: 34,
                                            fontWeight: FontWeight.w900,
                                            fontStyle: FontStyle.italic,
                                            color: context.colors.primary,
                                          ),
                                        ),
                                        TextSpan(
                                          text: "you in.",
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
                                    'Enter your mobile number to get started with end-to-end encrypted chats.',
                                    style: context.bodyMedium.copyWith(
                                      color: context.colors.textSecondary,
                                      fontSize: 14.5,
                                      height: 1.35,
                                    ),
                                  ),
                                  CommonSpaces.h24,

                                  // Phone Number Label
                                  Text(
                                    'Phone number',
                                    style: context.titleSmall.copyWith(
                                      color: context.colors.textSecondary,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  CommonSpaces.h8,

                                  // Phone Input Field
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: inputBgColor,
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: _phoneFocusNode.hasFocus
                                            ? context.colors.primary
                                            : (isDark
                                                ? Colors.white.withValues(alpha: 0.12)
                                                : context.colors.primary.withValues(alpha: 0.28)),
                                        width: _phoneFocusNode.hasFocus ? 1.8 : 1.2,
                                      ),
                                      boxShadow: _phoneFocusNode.hasFocus
                                          ? [
                                              BoxShadow(
                                                color: context.colors.primary.withValues(alpha: 0.18),
                                                blurRadius: 12,
                                                offset: const Offset(0, 3),
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
                                    child: Row(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(left: 14, right: 8),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Text(
                                                '🇮🇳',
                                                style: TextStyle(fontSize: 20),
                                              ),
                                              CommonSpaces.w6,
                                              Text(
                                                '+91',
                                                style: context.titleMedium.copyWith(
                                                  color: context.colors.textPrimary,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 15.5,
                                                ),
                                              ),
                                              CommonSpaces.w4,
                                              Icon(
                                                Icons.keyboard_arrow_down_rounded,
                                                size: 18,
                                                color: context.colors.textSecondary,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          height: 24,
                                          width: 1,
                                          color: isDark
                                              ? Colors.white.withValues(alpha: 0.15)
                                              : const Color(0xFFD1D5DB),
                                        ),
                                        CommonSpaces.w8,
                                        Expanded(
                                          child: TextField(
                                            controller: _mobileController,
                                            focusNode: _phoneFocusNode,
                                            autofocus: true,
                                            keyboardType: TextInputType.phone,
                                            inputFormatters: [
                                              FilteringTextInputFormatter.digitsOnly,
                                              LengthLimitingTextInputFormatter(10),
                                            ],
                                            maxLength: 10,
                                            style: context.titleMedium.copyWith(
                                              color: context.colors.textPrimary,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 1.5,
                                              fontSize: 16,
                                            ),
                                            decoration: InputDecoration(
                                              hintText: '000 000 0000',
                                              counterText: '',
                                              hintStyle: context.bodyMedium.copyWith(
                                                color: context.colors.textSecondary
                                                    .withValues(alpha: 0.45),
                                                letterSpacing: 1.5,
                                                fontSize: 16,
                                              ),
                                              border: InputBorder.none,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 14,
                                              ),
                                            ),
                                            onChanged: (_) => setState(() {}),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  CommonSpaces.h24,

                                  // Continue Button
                                  PrimaryActionButton(
                                    title: 'Continue',
                                    isLoading: isLoading,
                                    onPressed: isLoading ? null : () => _sendOtp(context),
                                  ),

                                  CommonSpaces.h20,

                                  // Terms & Privacy
                                  Center(
                                    child: Text.rich(
                                      TextSpan(
                                        text: 'By continuing you agree to our\n',
                                        style: context.bodySmall.copyWith(
                                          color: context.colors.textSecondary,
                                          height: 1.4,
                                          fontSize: 12.5,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: 'Terms',
                                            style: context.bodySmall.copyWith(
                                              color: context.colors.primary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12.5,
                                            ),
                                          ),
                                          const TextSpan(text: ' & '),
                                          TextSpan(
                                            text: 'Privacy Policy',
                                            style: context.bodySmall.copyWith(
                                              color: context.colors.primary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  CommonSpaces.h20,
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
        },
      ),
    );
  }
}

