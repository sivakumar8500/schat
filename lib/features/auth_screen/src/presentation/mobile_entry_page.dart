import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schat/features/auth_screen/src/presentation/bloc/auth_bloc.dart';
import 'package:schat/features/auth_screen/src/presentation/bloc/auth_event.dart';
import 'package:schat/features/auth_screen/src/presentation/bloc/auth_state.dart';
import 'package:schat/features/auth_screen/src/presentation/otp_verify_page.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_icons.dart';
import 'package:schat/utils/common_notifications.dart';
import 'package:schat/utils/common_sizes.dart';
import 'package:schat/utils/common_spaces.dart';
import 'package:sms_autofill/sms_autofill.dart';

class MobileEntryPage extends StatefulWidget {
  const MobileEntryPage({super.key});

  @override
  State<MobileEntryPage> createState() => _MobileEntryPageState();
}

class _MobileEntryPageState extends State<MobileEntryPage> {
  final TextEditingController _mobileController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchMobileNumber();
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
    final fieldBgColor = context.colors.pureWhite.withValues(alpha: 0.1);

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
                body: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: IntrinsicHeight(
                          child: Column(
                            children: [
                              const Spacer(),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.35,
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: Image.asset(
                                        'assets/main_bg_img.png',
                                        fit: BoxFit.cover,
                                      ),
                                    ),
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
                                              context.colors.pureBlack
                                                  .withValues(alpha: 0),
                                              context.colors.pureBlack,
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              CommonSpaces.h20,
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32.0,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text.rich(
                                            TextSpan(
                                              children: [
                                                TextSpan(
                                                  text: "Let's ",
                                                  style: context.h1.copyWith(
                                                    fontSize: 36,
                                                    color: context
                                                        .colors
                                                        .pureWhite,
                                                  ),
                                                ),
                                                TextSpan(
                                                  text: "get ",
                                                  style: context.h1Italic
                                                      .copyWith(
                                                        fontSize: 34,
                                                        color: context
                                                            .colors
                                                            .pureWhite,
                                                      ),
                                                ),
                                                TextSpan(
                                                  text: "you in.",
                                                  style: context.h1.copyWith(
                                                    fontSize: 36,
                                                    color: context
                                                        .colors
                                                        .pureWhite,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    CommonSpaces.h24,
                                    Text(
                                      'Phone number',
                                      style: context.titleSmall.copyWith(
                                        color: context.colors.pureWhite,
                                      ),
                                    ),
                                    CommonSpaces.h12,
                                    SizedBox(
                                      height: CommonSizes.p40,
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 6,
                                            ),

                                            decoration: BoxDecoration(
                                              color: fieldBgColor,
                                               borderRadius: BorderRadius.circular(
                                                16,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  '🇮🇳',
                                                  style: context.bodyLarge
                                                      .copyWith(fontSize: 22),
                                                ),
                                                CommonSpaces.w8,
                                                Text(
                                                  '+91',
                                                  style: context.titleSmall
                                                      .copyWith(
                                                        color: context
                                                            .colors
                                                            .pureWhite,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          CommonSpaces.w12,
                                          Expanded(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: fieldBgColor,
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              child: TextField(
                                                controller: _mobileController,
                                                keyboardType: TextInputType.phone,
                                                inputFormatters: [
                                                  FilteringTextInputFormatter.digitsOnly,
                                                  LengthLimitingTextInputFormatter(10),
                                                ],
                                                maxLength: 10,
                                                style: context.titleSmall
                                                    .copyWith(
                                                      color: context
                                                          .colors
                                                          .pureWhite,
                                                    ),
                                                decoration: InputDecoration(
                                                  hintText: '000 000 0000',
                                                  counterText: '',
                                                  hintStyle: context.bodyMedium
                                                      .copyWith(
                                                        color: context
                                                            .colors
                                                            .pureWhite
                                                            .withValues(
                                                              alpha: 0.4,
                                                            ),
                                                      ),
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(16),
                                                    borderSide: BorderSide.none,
                                                  ),
                                                  contentPadding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 20,
                                                        vertical: 6,
                                                      ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
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
                bottomNavigationBar: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton(
                            onPressed: isLoading
                                ? null
                                : () => _sendOtp(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.colors.primary,
                              foregroundColor: context.colors.pureWhite,
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
                                    color: context.colors.pureWhite,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                CommonSpaces.w8,
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: context.colors.pureWhite,
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
                        CommonSpaces.h24,
                        Center(
                          child: Text.rich(
                            TextSpan(
                              text: 'By continuing you agree to our\n',
                              style: context.bodyMedium.copyWith(
                                color: context.colors.pureWhite.withValues(
                                  alpha: 0.5,
                                ),
                                height: 1.4,
                              ),
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
                        CommonSpaces.h14,
                      ],
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
