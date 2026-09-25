import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schat/core/storage/storage_service.dart';
import 'package:schat/features/chat_transfer_screen/src/presentation/bloc/chat_transfer_bloc.dart';
import 'package:schat/features/chat_transfer_screen/src/presentation/bloc/chat_transfer_event.dart';
import 'package:schat/features/dashboard_screen/src/domain/repositories/contacts_repository.dart';
import 'package:schat/features/profile_screen/src/domain/models/user_model.dart';
import 'package:schat/injection.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fonts.dart';
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
      backgroundColor: Colors.transparent,
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
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _manualIdController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  List<UserModel> _allContacts = [];
  List<UserModel> _filteredContacts = [];
  UserModel? _selectedUser;
  bool _isLoading = true;
  bool _showManualInput = false;

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _manualIdController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);
    try {
      final repo = getIt<ContactsRepository>();
      final myId = getIt<StorageService>().getUserId() ?? '';
      
      var contacts = await repo.getCachedContacts();
      if (contacts.isEmpty) {
        final result = await repo.fetchSyncedContacts();
        result.when(
          success: (data) => contacts = data,
          failure: (_, _) {},
        );
      }

      final validContacts = contacts
          .where((u) => u.id.isNotEmpty && u.id != myId)
          .toList();

      if (mounted) {
        setState(() {
          _allContacts = validContacts;
          _filteredContacts = validContacts;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading contacts in SendViewRequestSheet: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() => _filteredContacts = _allContacts);
    } else {
      setState(() {
        _filteredContacts = _allContacts.where((user) {
          final name = user.displayName.toLowerCase();
          final phone = user.phoneNumber.toLowerCase();
          final username = (user.username ?? '').toLowerCase();
          final id = user.id.toLowerCase();
          return name.contains(query) ||
              phone.contains(query) ||
              username.contains(query) ||
              id.contains(query);
        }).toList();
      });
    }
  }

  void _submit() {
    String targetId = '';
    if (_showManualInput) {
      if (_formKey.currentState?.validate() != true) return;
      targetId = _manualIdController.text.trim();
    } else {
      if (_selectedUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please select a user to send request'),
            backgroundColor: context.colors.error,
          ),
        );
        return;
      }
      targetId = _selectedUser!.id;
    }

    if (targetId.isNotEmpty) {
      context.read<ChatTransferBloc>().add(SendChatTransferRequest(targetId));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sheetHeight = MediaQuery.of(context).size.height * 0.75;

    return Container(
      height: sheetHeight,
      decoration: BoxDecoration(
        color: context.colors.scaffoldBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Handle Bar
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: context.colors.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header Section
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 16, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: context.colors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.supervisor_account_rounded,
                      color: context.colors.primary,
                      size: 22,
                    ),
                  ),
                  CommonSpaces.w12,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Request Chat Monitoring',
                          style: context.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        CommonSpaces.h2,
                        Text(
                          'Select a contact to monitor their chat conversations.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: context.colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Search Bar & Manual Input Switch
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Column(
                children: [
                  if (!_showManualInput)
                    Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: context.colors.cardBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: context.colors.border.withValues(alpha: 0.6),
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(
                          fontSize: 14,
                          color: context.colors.textPrimary,
                          fontFamily: CommonFonts.primaryFont,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search contacts by name or phone...',
                          hintStyle: TextStyle(
                            fontSize: 13.5,
                            color: context.colors.textHint,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            size: 20,
                            color: context.colors.textSecondary,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    )
                  else
                    Form(
                      key: _formKey,
                      child: TextFormField(
                        controller: _manualIdController,
                        style: CommonFontStyles.bodyLarge(context),
                        decoration: InputDecoration(
                          hintText: 'Enter User UUID / ID manually',
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
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a valid User ID';
                          }
                          return null;
                        },
                      ),
                    ),
                  
                  // Toggle Manual / Contact Mode
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _showManualInput = !_showManualInput;
                          _selectedUser = null;
                        });
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        _showManualInput
                            ? 'Select from Contacts instead'
                            : 'Or enter User ID manually',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.colors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Contacts List Area
            Expanded(
              child: _showManualInput
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.pin_outlined,
                              size: 44,
                              color: context.colors.primary.withValues(alpha: 0.6),
                            ),
                            CommonSpaces.h12,
                            Text(
                              'Manual Target Entry',
                              style: context.titleMedium.copyWith(fontWeight: FontWeight.bold),
                            ),
                            CommonSpaces.h6,
                            Text(
                              'Type or paste the specific user UUID you want to monitor.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: context.colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _isLoading
                      ? Center(child: CircularProgressIndicator(color: context.colors.primary))
                      : _filteredContacts.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.person_search_rounded,
                                      size: 48,
                                      color: context.colors.textSecondary.withValues(alpha: 0.5),
                                    ),
                                    CommonSpaces.h12,
                                    Text(
                                      _searchController.text.isNotEmpty
                                          ? 'No matching contacts found'
                                          : 'No contacts available on sChat',
                                      style: context.titleMedium.copyWith(fontWeight: FontWeight.w600),
                                    ),
                                    CommonSpaces.h6,
                                    Text(
                                      'You can enter their User ID manually using the button above.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: context.colors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: _filteredContacts.length,
                              separatorBuilder: (_, _) => const Divider(height: 1, indent: 64),
                              itemBuilder: (context, index) {
                                final user = _filteredContacts[index];
                                final isSelected = _selectedUser?.id == user.id;

                                return _buildContactTile(user, isSelected);
                              },
                            ),
            ),

            // Bottom Submit Button
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                color: context.colors.scaffoldBackground,
                border: Border(
                  top: BorderSide(
                    color: context.colors.border.withValues(alpha: 0.4),
                  ),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: (_showManualInput || _selectedUser != null) ? _submit : null,
                  icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                  label: Text(
                    _selectedUser != null
                        ? 'Request Access to ${_selectedUser!.displayName}'
                        : 'Send View Request',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.primary,
                    disabledBackgroundColor: context.colors.primary.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactTile(UserModel user, bool isSelected) {
    final initials = user.displayName.isNotEmpty
        ? user.displayName.substring(0, 1).toUpperCase()
        : '?';

    return InkWell(
      onTap: () {
        setState(() {
          if (_selectedUser?.id == user.id) {
            _selectedUser = null;
          } else {
            _selectedUser = user;
          }
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? context.colors.primary.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: context.colors.primary.withValues(alpha: 0.5), width: 1.5)
              : null,
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 22,
              backgroundColor: isSelected
                  ? context.colors.primary
                  : context.colors.primary.withValues(alpha: 0.15),
              backgroundImage: user.profilePictureUrl != null &&
                      user.profilePictureUrl!.isNotEmpty
                  ? NetworkImage(user.profilePictureUrl!)
                  : null,
              child: user.profilePictureUrl == null ||
                      user.profilePictureUrl!.isEmpty
                  ? Text(
                      initials,
                      style: TextStyle(
                        color: isSelected ? Colors.white : context.colors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    )
                  : null,
            ),
            CommonSpaces.w12,

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected
                          ? context.colors.primary
                          : context.colors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  CommonSpaces.h2,
                  Text(
                    user.phoneNumber.isNotEmpty
                        ? user.phoneNumber
                        : (user.username != null ? '@${user.username}' : user.id),
                    style: TextStyle(
                      fontSize: 13,
                      color: context.colors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Selection Indicator
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? context.colors.primary : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? context.colors.primary
                      : context.colors.border.withValues(alpha: 0.8),
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
