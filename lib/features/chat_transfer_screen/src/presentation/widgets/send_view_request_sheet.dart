import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schat/features/chat_transfer_screen/src/presentation/bloc/chat_transfer_bloc.dart';
import 'package:schat/features/chat_transfer_screen/src/presentation/bloc/chat_transfer_event.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_icons.dart';
import 'package:schat/utils/common_spaces.dart';

class SendViewRequestSheet extends StatefulWidget {
  const SendViewRequestSheet({super.key});

  static Future<void> show(BuildContext context) {
    final bloc = context.read<ChatTransferBloc>();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.scaffoldBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: const SendViewRequestSheet(),
      ),
    );
  }

  @override
  State<SendViewRequestSheet> createState() => _SendViewRequestSheetState();
}

class _SendViewRequestSheetState extends State<SendViewRequestSheet> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() == true) {
      final target = _controller.text.trim();
      context.read<ChatTransferBloc>().add(SendChatTransferRequest(target));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            CommonSpaces.h16,
            Text(
              'Request Chat Monitoring',
              style: CommonFontStyles.titleLarge(context),
            ),
            CommonSpaces.h6,
            Text(
              'Send a permission request to monitor another user’s conversations. They must accept before you can view their chats.',
              style: CommonFontStyles.bodyMedium(context).copyWith(
                color: context.colors.textSecondary,
              ),
            ),
            CommonSpaces.h20,
            TextFormField(
              controller: _controller,
              keyboardType: TextInputType.text,
              style: CommonFontStyles.bodyLarge(context),
              decoration: InputDecoration(
                hintText: 'Enter User ID or UUID',
                hintStyle: CommonFontStyles.bodyMedium(context).copyWith(
                  color: context.colors.textHint,
                ),
                prefixIcon: Icon(CommonIcons.person, color: context.colors.primary),
                filled: true,
                fillColor: context.colors.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.colors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.colors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.colors.primary, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a valid User ID';
                }
                return null;
              },
            ),
            CommonSpaces.h24,
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _submit,
                icon: Icon(CommonIcons.send, color: Colors.white, size: 18),
                label: Text(
                  'Send View Request',
                  style: CommonFontStyles.buttonText(context).copyWith(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
