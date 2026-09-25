import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schat/features/status_screen/src/domain/status_model.dart';
import 'package:schat/features/status_screen/src/presentation/bloc/status_bloc.dart';
import 'package:schat/features/status_screen/src/presentation/bloc/status_event.dart';
import 'package:schat/features/status_screen/src/presentation/bloc/status_state.dart';
import 'package:schat/features/status_screen/src/presentation/widgets/status_contact_picker_sheet.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_notifications.dart';
import 'package:schat/utils/common_spaces.dart';

class StatusPrivacySheet extends StatefulWidget {
  const StatusPrivacySheet({super.key});

  @override
  State<StatusPrivacySheet> createState() => _StatusPrivacySheetState();
}

class _StatusPrivacySheetState extends State<StatusPrivacySheet> {
  @override
  void initState() {
    super.initState();
    context.read<StatusBloc>().add(const FetchStatusPrivacyEvent());
  }

  void _openContactPicker(
    BuildContext context,
    ContactPickerMode mode,
    List<String> currentSelectedIds,
  ) async {
    final List<String>? updatedIds = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatusContactPickerSheet(
        mode: mode,
        initialSelectedIds: currentSelectedIds,
      ),
    );

    if (updatedIds != null && context.mounted) {
      final isExclude = mode == ContactPickerMode.exclude;
      final privacyType = isExclude ? 'except' : 'only';

      context.read<StatusBloc>().add(
            UpdateStatusPrivacyEvent(
              privacyType: privacyType,
              excludedUserIds: isExclude ? updatedIds : null,
              includedUserIds: !isExclude ? updatedIds : null,
            ),
          );

      context.showSuccessNotification(
        isExclude
            ? 'Excluded ${updatedIds.length} contacts'
            : 'Sharing with ${updatedIds.length} contacts',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.scaffoldBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: BlocBuilder<StatusBloc, StatusState>(
        builder: (context, state) {
          StatusPrivacyModel privacy = const StatusPrivacyModel(privacyType: 'contacts');
          if (state is StatusLoaded && state.privacyModel != null) {
            privacy = state.privacyModel!;
          }

          final rawType = (privacy.privacyType ?? 'contacts').toLowerCase();
          final isAll = rawType == 'contacts' || rawType == 'all' || rawType == 'my_contacts';
          final isExclude = rawType == 'except' || rawType == 'exclude' || rawType == 'excluded' || rawType == 'my_contacts_except';
          final isInclude = rawType == 'only' || rawType == 'include' || rawType == 'included' || rawType == 'only_share_with' || rawType == 'only_share';

          final excludedCount = privacy.excludedUserIds.length;
          final includedCount = privacy.includedUserIds.length;

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: context.colors.textHint.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Status Privacy',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: context.colors.textPrimary,
                ),
              ),
              CommonSpaces.h4,
              Text(
                'Who can see my status updates',
                style: TextStyle(
                  fontSize: 13,
                  color: context.colors.textSecondary,
                ),
              ),
              CommonSpaces.h16,

              // Option 1: My Contacts (All)
              _privacyRadioOption(
                context,
                title: 'My contacts (All)',
                subtitle: 'Share with all your contacts',
                isSelected: isAll,
                onTap: () {
                  context.read<StatusBloc>().add(
                        const UpdateStatusPrivacyEvent(privacyType: 'contacts'),
                      );
                  context.showSuccessNotification('Privacy set to My contacts (All)');
                },
              ),

              // Option 2: My contacts except... (Excluding)
              _privacyRadioOption(
                context,
                title: 'My contacts except... (Excluding)',
                subtitle: excludedCount > 0
                    ? '$excludedCount contacts excluded'
                    : 'Select contacts to exclude',
                isSelected: isExclude,
                onTap: () {
                  _openContactPicker(
                    context,
                    ContactPickerMode.exclude,
                    privacy.excludedUserIds,
                  );
                },
              ),

              // Option 3: Only share with... (Including)
              _privacyRadioOption(
                context,
                title: 'Only share with... (Including)',
                subtitle: includedCount > 0
                    ? '$includedCount contacts included'
                    : 'Select contacts to share with',
                isSelected: isInclude,
                onTap: () {
                  _openContactPicker(
                    context,
                    ContactPickerMode.include,
                    privacy.includedUserIds,
                  );
                },
              ),


              CommonSpaces.h16,
              Divider(color: context.colors.textHint.withValues(alpha: 0.15)),
              CommonSpaces.h8,
              Text(
                'Changes to your privacy settings won\'t affect status updates that you\'ve sent already.',
                style: TextStyle(
                  fontSize: 12,
                  color: context.colors.textHint,
                  height: 1.4,
                ),
              ),
              CommonSpaces.h16,
            ],
          );
        },
      ),
    );
  }

  Widget _privacyRadioOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? context.colors.primary.withValues(alpha: 0.08)
            : context.colors.lightBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? context.colors.primary
              : context.colors.textHint.withValues(alpha: 0.1),
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? context.colors.primary : context.colors.textHint,
              width: isSelected ? 6.5 : 2.0,
            ),
          ),
        ),

        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: context.colors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? context.colors.primary : context.colors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        trailing: isSelected
            ? Icon(Icons.arrow_forward_ios, size: 14, color: context.colors.primary)
            : Icon(Icons.chevron_right, size: 20, color: context.colors.textHint),
      ),
    );
  }
}
