import 'package:flutter/material.dart';
import 'package:schat/features/chat_screen/src/domain/repositories/chat_repository.dart';
import 'package:schat/features/chat_screen/src/presentation/widgets/forgot_chat_lock_bottom_sheet.dart';
import 'package:schat/core/storage/storage_service.dart';
import 'package:schat/injection.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_notifications.dart';
import 'package:schat/utils/common_spaces.dart';

class UnlockChatBottomSheet extends StatefulWidget {
  final String conversationId;
  final String? contactName;

  const UnlockChatBottomSheet({
    super.key,
    required this.conversationId,
    this.contactName,
  });

  static Future<bool> show(
    BuildContext context, {
    required String conversationId,
    String? contactName,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UnlockChatBottomSheet(
        conversationId: conversationId,
        contactName: contactName,
      ),
    );
    return result ?? false;
  }

  @override
  State<UnlockChatBottomSheet> createState() => _UnlockChatBottomSheetState();
}

class _UnlockChatBottomSheetState extends State<UnlockChatBottomSheet> {
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _passwordFocusNode = FocusNode();

  bool _isVerifying = false;
  bool _obscurePassword = true;
  String? _errorMessage;


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _passwordFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }


  Future<void> _verifyAndUnlock() async {
    final code = _passwordController.text.trim();
    if (code.isEmpty) {
      setState(() => _errorMessage = 'Please enter your secret code');
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      final repo = getIt<ChatRepository>();
      final isValid = await repo.verifyChatLockPassword(code);

      if (!mounted) return;

      if (isValid) {
        if (widget.conversationId.isNotEmpty) {
          try {
            getIt<StorageService>().saveChatLocked(widget.conversationId, true);
          } catch (_) {}
        }
        Navigator.pop(context, true);
      } else {
        setState(() {
          _isVerifying = false;
          _errorMessage = 'Incorrect secret code. Please try again.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVerifying = false;
          _errorMessage = 'Verification error: $e';
        });
      }
    }
  }

  void _showForgotPasscode() {
    ForgotChatLockBottomSheet.show(
      context,
      onPasswordReset: () {
        if (mounted) {
          context.showSuccessNotification('Secret code reset successfully. Enter your new code.');
          setState(() {
            _passwordController.clear();
            _errorMessage = null;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.colors.isDark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    const primaryColor = Color(0xFF00873C);

    return Container(
      decoration: BoxDecoration(
        color: context.colors.scaffoldBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomInset),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Top drag indicator
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: context.colors.textHint.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Lock Icon Header
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: isDark
                      ? primaryColor.withValues(alpha: 0.2)
                      : const Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.lock_rounded,
                    color: primaryColor,
                    size: 32,
                  ),
                ),
              ),
              CommonSpaces.h16,

              // Title
              Text(
                'Chat Locked',
                style: context.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.colors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              CommonSpaces.h8,

              // Subtitle
              Text(
                widget.contactName != null &&
                        widget.contactName!.isNotEmpty &&
                        widget.contactName != 'Chat' &&
                        widget.contactName != 'sChat'
                    ? 'Enter your secret code to view chat with ${widget.contactName}.'
                    : 'Enter your secret code to view this locked conversation.',
                style: context.bodyMedium.copyWith(
                  color: context.colors.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              CommonSpaces.h24,

              // Secret Code Input Field
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _errorMessage != null
                        ? const Color(0xFFD92D20)
                        : context.colors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: TextField(
                  controller: _passwordController,
                  focusNode: _passwordFocusNode,
                  obscureText: _obscurePassword,
                  style: TextStyle(
                    fontSize: 16,
                    color: context.colors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter Secret Code (text, emojis, pin)',
                    hintStyle: TextStyle(
                      color: context.colors.textHint,
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(Icons.key_rounded, color: primaryColor, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        color: context.colors.textSecondary,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  onSubmitted: (_) => _verifyAndUnlock(),
                ),
              ),


              // Error banner if any
              if (_errorMessage != null) ...[
                CommonSpaces.h12,
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE4E2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Color(0xFFD92D20), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Color(0xFFD92D20),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              CommonSpaces.h20,

              // Unlock Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isVerifying ? null : _verifyAndUnlock,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0,
                  ),
                  child: _isVerifying
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Unlock & Open Chat',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),

              CommonSpaces.h10,

              // Forgot Code & Cancel
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _isVerifying ? null : () => Navigator.pop(context, false),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: context.colors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _isVerifying ? null : _showForgotPasscode,
                    icon: const Icon(Icons.help_outline_rounded, size: 16, color: primaryColor),
                    label: const Text(
                      'Forgot Secret Code?',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
