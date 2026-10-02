import 'package:flutter/material.dart';
import 'package:schat/features/chat_screen/src/domain/repositories/chat_repository.dart';
import 'package:schat/injection.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_notifications.dart';
import 'package:schat/utils/common_spaces.dart';

class ChatLockBottomSheet extends StatefulWidget {
  final String conversationId;
  final String contactName;
  final bool isCurrentlyLocked;

  const ChatLockBottomSheet({
    super.key,
    required this.conversationId,
    required this.contactName,
    this.isCurrentlyLocked = false,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String conversationId,
    required String contactName,
    bool isCurrentlyLocked = false,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChatLockBottomSheet(
        conversationId: conversationId,
        contactName: contactName,
        isCurrentlyLocked: isCurrentlyLocked,
      ),
    );
  }

  @override
  State<ChatLockBottomSheet> createState() => _ChatLockBottomSheetState();
}

class _ChatLockBottomSheetState extends State<ChatLockBottomSheet> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _oldPasswordController = TextEditingController();

  bool _isLoadingStatus = true;
  bool _isActionProcessing = false;
  bool _hasPassword = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _obscureOldPassword = true;
  bool _isChangingPassword = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkLockStatus();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _oldPasswordController.dispose();
    super.dispose();
  }

  Future<void> _checkLockStatus() async {
    setState(() {
      _isLoadingStatus = true;
      _errorMessage = null;
    });

    try {
      final repo = getIt<ChatRepository>();
      final status = await repo.getChatLockStatus();
      if (mounted) {
        setState(() {
          _hasPassword = status.hasPassword;
          _isLoadingStatus = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingStatus = false;
          _errorMessage = 'Could not load lock status: $e';
        });
      }
    }
  }

  Future<void> _handleAction() async {
    final password = _passwordController.text.trim();

    if (password.isEmpty) {
      setState(() => _errorMessage = 'Please enter a secret code');
      return;
    }

    // Creating password for the first time
    if (!_hasPassword && !widget.isCurrentlyLocked && !_isChangingPassword) {
      final confirmPassword = _confirmPasswordController.text.trim();
      if (confirmPassword.isEmpty) {
        setState(() => _errorMessage = 'Please confirm your secret code');
        return;
      }
      if (password != confirmPassword) {
        setState(() => _errorMessage = 'Secret codes do not match');
        return;
      }
    }

    // Changing password
    if (_isChangingPassword) {
      final oldPassword = _oldPasswordController.text.trim();
      final confirmPassword = _confirmPasswordController.text.trim();
      if (oldPassword.isEmpty) {
        setState(() => _errorMessage = 'Please enter your current secret code');
        return;
      }
      if (password != confirmPassword) {
        setState(() => _errorMessage = 'New secret codes do not match');
        return;
      }
    }

    setState(() {
      _isActionProcessing = true;
      _errorMessage = null;
    });

    try {
      final repo = getIt<ChatRepository>();

      if (_isChangingPassword) {
        final oldPassword = _oldPasswordController.text.trim();
        final success = await repo.setChatLockPassword(
          password,
          oldPassword: oldPassword,
        );
        if (mounted) {
          setState(() => _isActionProcessing = false);
          if (success) {
            context.showSuccessNotification('Secret code changed successfully');
            Navigator.pop(context, false);
          } else {
            setState(() => _errorMessage = 'Failed to change secret code. Verify old code.');
          }
        }
        return;
      }

      if (!_hasPassword) {
        // Set password first
        final setSuccess = await repo.setChatLockPassword(password);
        if (!setSuccess) {
          if (mounted) {
            setState(() {
              _isActionProcessing = false;
              _errorMessage = 'Failed to set secret code. Please try again.';
            });
          }
          return;
        }
      } else {
        // Verify existing password
        final isValid = await repo.verifyChatLockPassword(password);
        if (!isValid) {
          if (mounted) {
            setState(() {
              _isActionProcessing = false;
              _errorMessage = 'Incorrect secret code. Please enter the secret code you set for Chat Lock.';
            });
          }
          return;
        }
      }

      // Now toggle lock
      final targetLockState = !widget.isCurrentlyLocked;
      final lockSuccess = await repo.toggleChatLock(
        widget.conversationId,
        isLocked: targetLockState,
        password: password,
      );

      if (mounted) {
        setState(() => _isActionProcessing = false);
        if (lockSuccess) {
          if (targetLockState) {
            context.showSuccessNotification('Chat locked. Type your code in search to find it.');
          } else {
            context.showSuccessNotification('Chat unlocked successfully');
          }
          Navigator.pop(context, true);
        } else {
          setState(() => _errorMessage = widget.isCurrentlyLocked
              ? 'Incorrect secret code'
              : 'Failed to lock chat. Check your secret code.');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isActionProcessing = false;
          _errorMessage = 'Error: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.colors.isDark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

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

              // Header Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: widget.isCurrentlyLocked
                      ? const Color(0xFFFEF3F2)
                      : (isDark
                          ? context.colors.primary.withValues(alpha: 0.2)
                          : const Color(0xFFE8F5E9)),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    widget.isCurrentlyLocked
                        ? Icons.lock_open_rounded
                        : Icons.lock_rounded,
                    color: widget.isCurrentlyLocked
                        ? const Color(0xFFD92D20)
                        : (isDark ? const Color(0xFF00FF87) : const Color(0xFF00873C)),
                    size: 32,
                  ),
                ),
              ),
              CommonSpaces.h16,

              // Title
              Text(
                _isChangingPassword
                    ? 'Change Secret Code'
                    : widget.isCurrentlyLocked
                        ? 'Unlock Chat'
                        : !_hasPassword
                            ? 'Create Secret Code & Lock Chat'
                            : 'Lock Chat',
                style: context.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.colors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              CommonSpaces.h8,

              // Subtitle description
              Text(
                _isChangingPassword
                    ? 'Enter your current secret code and choose a new one. Supports words, emojis, symbols, and numbers.'
                    : widget.isCurrentlyLocked
                        ? 'Enter your secret code to unlock chat with ${widget.contactName}.'
                        : !_hasPassword
                            ? 'Keep this chat hidden and secured. Create a secret code (use words, emojis 🔒🍕, symbols @#\$, or numbers). Type this code into the search bar to reveal locked chats.'
                            : 'Enter your secret code to lock and hide chat with ${widget.contactName}.',
                style: context.bodyMedium.copyWith(
                  color: context.colors.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              CommonSpaces.h24,

              if (_isLoadingStatus)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: CircularProgressIndicator(color: context.colors.primary),
                )
              else ...[
                // If changing password, show Old Password field
                if (_isChangingPassword) ...[
                  _buildTextField(
                    controller: _oldPasswordController,
                    hintText: 'Current Secret Code',
                    prefixIcon: Icons.lock_clock_outlined,
                    obscureText: _obscureOldPassword,
                    onToggleObscure: () => setState(() => _obscureOldPassword = !_obscureOldPassword),
                    isDark: isDark,
                  ),
                  CommonSpaces.h16,
                ],

                // Main Secret Code field
                _buildTextField(
                  controller: _passwordController,
                  hintText: _isChangingPassword
                      ? 'New Secret Code (e.g. 🔒Secret@123🍕)'
                      : !_hasPassword
                          ? 'Set Secret Code (e.g. 🔒Secret@123🍕)'
                          : 'Enter Secret Code',
                  prefixIcon: Icons.key_rounded,
                  obscureText: _obscurePassword,
                  onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                  isDark: isDark,
                ),

                // Confirm Password field when setting code for first time or changing
                if ((!_hasPassword && !widget.isCurrentlyLocked) || _isChangingPassword) ...[
                  CommonSpaces.h16,
                  _buildTextField(
                    controller: _confirmPasswordController,
                    hintText: 'Confirm Secret Code',
                    prefixIcon: Icons.check_circle_outline_rounded,
                    obscureText: _obscureConfirmPassword,
                    onToggleObscure: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    isDark: isDark,
                  ),
                ],

                // Error message display
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
                            style: const TextStyle(color: Color(0xFFD92D20), fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                CommonSpaces.h24,

                // Action Buttons
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isActionProcessing ? null : _handleAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.isCurrentlyLocked
                          ? const Color(0xFFD92D20)
                          : context.colors.primary,
                      foregroundColor: widget.isCurrentlyLocked
                          ? Colors.white
                          : (isDark ? Colors.black : Colors.white),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 0,
                    ),
                    child: _isActionProcessing
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            _isChangingPassword
                                ? 'Update Secret Code'
                                : widget.isCurrentlyLocked
                                    ? 'Unlock Chat'
                                    : !_hasPassword
                                        ? 'Set Code & Lock Chat'
                                        : 'Lock Chat',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                // Toggle Change Password option if user already has password set
                if (_hasPassword && !widget.isCurrentlyLocked) ...[
                  CommonSpaces.h12,
                  TextButton(
                    onPressed: _isActionProcessing
                        ? null
                        : () {
                            setState(() {
                              _isChangingPassword = !_isChangingPassword;
                              _errorMessage = null;
                              _passwordController.clear();
                              _confirmPasswordController.clear();
                              _oldPasswordController.clear();
                            });
                          },
                    child: Text(
                      _isChangingPassword ? 'Cancel Change Code' : 'Change Secret Code',
                      style: TextStyle(
                        color: context.colors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    required bool obscureText,
    required VoidCallback onToggleObscure,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.done,
        style: TextStyle(
          color: context.colors.textPrimary,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: context.colors.textHint,
            fontSize: 14,
          ),
          prefixIcon: Icon(prefixIcon, color: context.colors.textHint, size: 20),
          suffixIcon: IconButton(
            icon: Icon(
              obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: context.colors.textHint,
              size: 20,
            ),
            onPressed: onToggleObscure,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
