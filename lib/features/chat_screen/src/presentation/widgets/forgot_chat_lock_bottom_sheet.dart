import 'dart:async';
import 'package:flutter/material.dart';
import 'package:schat/core/storage/storage_service.dart';
import 'package:schat/features/auth_screen/src/domain/repositories/auth_repository.dart';
import 'package:schat/features/chat_screen/src/domain/repositories/chat_repository.dart';
import 'package:schat/features/profile_screen/src/domain/repositories/profile_repository.dart';
import 'package:schat/injection.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_notifications.dart';
import 'package:schat/utils/common_spaces.dart';

enum ForgotLockStep { sendOtp, verifyOtp, setNewPassword, success }

class ForgotChatLockBottomSheet extends StatefulWidget {
  final VoidCallback? onPasswordReset;

  const ForgotChatLockBottomSheet({
    super.key,
    this.onPasswordReset,
  });

  static Future<bool?> show(BuildContext context, {VoidCallback? onPasswordReset}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ForgotChatLockBottomSheet(onPasswordReset: onPasswordReset),
    );
  }

  @override
  State<ForgotChatLockBottomSheet> createState() => _ForgotChatLockBottomSheetState();
}

class _ForgotChatLockBottomSheetState extends State<ForgotChatLockBottomSheet> {
  ForgotLockStep _currentStep = ForgotLockStep.sendOtp;

  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final FocusNode _newPasswordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  String _phoneNumber = '';
  bool _isLoading = false;
  String? _errorMessage;

  bool _obscureNewPassword = false;
  bool _obscureConfirmPassword = false;

  int _resendCountdown = 30;
  Timer? _countdownTimer;

  static const List<String> _popularEmojis = [
    '🔒', '🔑', '🔐', '🤫', '❤️', '🔥', '⭐', '😎',
    '🤐', '🛡️', '💎', '🚀', '⚡', '🍀', '🎯', '👑',
    '✨', '🌸', '🐱', '🦋', '🌙', '🪄', '💎', '🦄',
  ];

  @override
  void initState() {
    super.initState();
    _initAndSendOtp();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _newPasswordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _initAndSendOtp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Resolve phone number
      String? phone = getIt<StorageService>().getPhoneNumber();
      if (phone == null || phone.isEmpty) {
        if (getIt.isRegistered<ProfileRepository>()) {
          final profileRes = await getIt<ProfileRepository>().getProfile();
          profileRes.when(
            success: (user) {
              phone = user.phoneNumber;
              if (phone != null && phone!.isNotEmpty) {
                getIt<StorageService>().savePhoneNumber(phone);
              }
            },
            failure: (_, _) {},
          );
        }
      }

      _phoneNumber = phone ?? '';

      if (_phoneNumber.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No registered phone number found for this account.';
        });
        return;
      }

      await _sendOtpRequest();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error sending OTP: $e';
        });
      }
    }
  }

  Future<void> _sendOtpRequest() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authRepo = getIt<AuthRepository>();
      final res = await authRepo.sendOtp(_phoneNumber);
      res.when(
        success: (_) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _currentStep = ForgotLockStep.verifyOtp;
            });
            _startResendTimer();
            context.showSuccessNotification('OTP sent to ${_maskPhone(_phoneNumber)}');
          }
        },
        failure: (msg, _) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _errorMessage = msg.isNotEmpty ? msg : 'Failed to send OTP. Please retry.';
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to send OTP: $e';
        });
      }
    }
  }

  void _startResendTimer() {
    _countdownTimer?.cancel();
    _resendCountdown = 30;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCountdown <= 1) {
        timer.cancel();
        setState(() {
          _resendCountdown = 0;
        });
      } else {
        setState(() {
          _resendCountdown--;
        });
      }
    });
  }

  String _maskPhone(String phone) {
    if (phone.length <= 4) return phone;
    final last4 = phone.substring(phone.length - 4);
    final prefix = phone.substring(0, phone.length - 4);
    final masked = prefix.replaceAll(RegExp(r'\d'), '•');
    return '$masked$last4';
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length < 4) {
      setState(() {
        _errorMessage = 'Please enter a valid 4-6 digit OTP code';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authRepo = getIt<AuthRepository>();
      final deviceId = getIt<StorageService>().getDeviceId();
      final res = await authRepo.verifyOtp(_phoneNumber, otp, deviceId);

      res.when(
        success: (_) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _currentStep = ForgotLockStep.setNewPassword;
            });
          }
        },
        failure: (msg, _) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _errorMessage = msg.isNotEmpty ? msg : 'Invalid or expired OTP. Please try again.';
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error verifying OTP: $e';
        });
      }
    }
  }

  Future<void> _submitNewPassword() async {
    final newPass = _newPasswordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();

    if (newPass.isEmpty) {
      setState(() => _errorMessage = 'Please enter a new secret code / password');
      return;
    }
    if (newPass != confirmPass) {
      setState(() => _errorMessage = 'Secret codes do not match');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = getIt<ChatRepository>();
      final success = await repo.setChatLockPassword(newPass);

      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          context.showSuccessNotification('Chat lock password reset successfully!');
          widget.onPasswordReset?.call();
          Navigator.pop(context, true);
        } else {
          setState(() {
            _errorMessage = 'Failed to update password. Please try again.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error updating password: $e';
        });
      }
    }
  }

  void _insertEmoji(String emoji) {
    TextEditingController targetController;
    if (_confirmPasswordFocusNode.hasFocus) {
      targetController = _confirmPasswordController;
    } else {
      targetController = _newPasswordController;
    }

    final currentText = targetController.text;
    final selection = targetController.selection;
    if (selection.start >= 0 && selection.end >= 0) {
      final newText = currentText.replaceRange(selection.start, selection.end, emoji);
      targetController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.start + emoji.length),
      );
    } else {
      targetController.text = currentText + emoji;
      targetController.selection = TextSelection.collapsed(offset: targetController.text.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = colors.isDark;
    final primaryColor = isDark ? const Color(0xFF00FF87) : const Color(0xFF00873C);

    return Container(
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colors.textHint.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          CommonSpaces.h16,

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _currentStep == ForgotLockStep.setNewPassword
                      ? Icons.lock_reset_rounded
                      : Icons.phonelink_lock_rounded,
                  color: primaryColor,
                  size: 22,
                ),
              ),
              CommonSpaces.w12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentStep == ForgotLockStep.setNewPassword
                          ? 'Set New Secret Code'
                          : 'Verify Phone Number',
                      style: context.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      _currentStep == ForgotLockStep.setNewPassword
                          ? 'Enter and confirm your new chat lock code'
                          : 'Enter the OTP sent to your registered mobile',
                      style: context.bodySmall.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, color: colors.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          CommonSpaces.h16,

          if (_errorMessage != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: colors.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded, color: colors.error, size: 18),
                  CommonSpaces.w8,
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: context.bodySmall.copyWith(
                        color: colors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            CommonSpaces.h12,
          ],

          if (_currentStep == ForgotLockStep.sendOtp) ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: CircularProgressIndicator(color: primaryColor),
              ),
            ),
          ] else if (_currentStep == ForgotLockStep.verifyOtp) ...[
            _buildOtpVerificationStep(colors, primaryColor),
          ] else if (_currentStep == ForgotLockStep.setNewPassword) ...[
            _buildSetNewPasswordStep(colors, primaryColor),
          ],
        ],
      ),
    );
  }

  Widget _buildOtpVerificationStep(dynamic colors, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: colors.lightBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.phone_android_rounded, size: 18, color: colors.textSecondary),
              CommonSpaces.w8,
              Text(
                'Mobile: ${_maskPhone(_phoneNumber)}',
                style: context.bodyMedium.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        CommonSpaces.h14,

        TextFormField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: context.titleLarge.copyWith(
            letterSpacing: 8,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
          decoration: InputDecoration(
            counterText: '',
            hintText: '• • • • • •',
            hintStyle: context.titleLarge.copyWith(
              letterSpacing: 8,
              color: colors.textHint,
            ),
            filled: true,
            fillColor: colors.lightBackground,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        CommonSpaces.h12,

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_resendCountdown > 0)
              Text(
                'Resend in ${_resendCountdown}s',
                style: context.bodySmall.copyWith(color: colors.textSecondary),
              )
            else
              TextButton(
                onPressed: _isLoading ? null : _sendOtpRequest,
                child: Text(
                  'Resend OTP',
                  style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        CommonSpaces.h16,

        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _verifyOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: colors.textLight,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text('Verify & Continue', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildSetNewPasswordStep(dynamic colors, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'NEW SECRET CODE / PASSWORD',
          style: context.bodySmall.copyWith(
            color: colors.textSecondary,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
        CommonSpaces.h6,

        TextFormField(
          controller: _newPasswordController,
          focusNode: _newPasswordFocusNode,
          obscureText: _obscureNewPassword,
          style: context.bodyLarge.copyWith(color: colors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Enter secret code (e.g. 1234 or 🔒🔑❤️)',
            hintStyle: context.bodyMedium.copyWith(color: colors.textHint),
            filled: true,
            fillColor: colors.lightBackground,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureNewPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                color: colors.textSecondary,
                size: 20,
              ),
              onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
            ),
          ),
        ),
        CommonSpaces.h12,

        Text(
          'CONFIRM SECRET CODE',
          style: context.bodySmall.copyWith(
            color: colors.textSecondary,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
        CommonSpaces.h6,

        TextFormField(
          controller: _confirmPasswordController,
          focusNode: _confirmPasswordFocusNode,
          obscureText: _obscureConfirmPassword,
          style: context.bodyLarge.copyWith(color: colors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Re-enter new secret code',
            hintStyle: context.bodyMedium.copyWith(color: colors.textHint),
            filled: true,
            fillColor: colors.lightBackground,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                color: colors.textSecondary,
                size: 20,
              ),
              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
            ),
          ),
        ),
        CommonSpaces.h12,

        // Quick Emoji Bar
        Row(
          children: [
            Icon(Icons.emoji_emotions_outlined, size: 16, color: primaryColor),
            CommonSpaces.w6,
            Text(
              'Add emojis to your passcode:',
              style: context.bodySmall.copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        CommonSpaces.h6,
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _popularEmojis.length,
            separatorBuilder: (_, _) => const SizedBox(width: 6),
            itemBuilder: (context, idx) {
              final emoji = _popularEmojis[idx];
              return InkWell(
                 onTap: () => _insertEmoji(emoji),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.lightBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: primaryColor.withValues(alpha: 0.15)),
                  ),
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 18)),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 18),

        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submitNewPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: colors.textLight,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text('Update Secret Code', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}
