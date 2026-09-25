import 'package:flutter/material.dart';
import 'package:schat/features/dashboard_screen/src/domain/repositories/contacts_repository.dart';
import 'package:schat/features/profile_screen/src/domain/models/user_model.dart';
import 'package:schat/injection.dart';
import 'package:schat/utils/common_colors.dart';

enum ContactPickerMode { exclude, include }

class StatusContactPickerSheet extends StatefulWidget {
  final ContactPickerMode mode;
  final List<String> initialSelectedIds;

  const StatusContactPickerSheet({
    super.key,
    required this.mode,
    required this.initialSelectedIds,
  });

  @override
  State<StatusContactPickerSheet> createState() => _StatusContactPickerSheetState();
}

class _StatusContactPickerSheetState extends State<StatusContactPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _allContacts = [];
  List<UserModel> _filteredContacts = [];
  late Set<String> _selectedUserIds;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedUserIds = Set.from(widget.initialSelectedIds);
    _loadContacts();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    final repository = getIt<ContactsRepository>();
    List<UserModel> contacts = [];
    final result = await repository.fetchSyncedContacts();
    result.when(
      success: (data) => contacts = data,
      failure: (_, _) => contacts = [],
    );
    if (contacts.isEmpty) {
      contacts = await repository.getCachedContacts();
    }

    if (mounted) {
      setState(() {
        _allContacts = contacts;
        _filteredContacts = contacts;
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredContacts = _allContacts;
      } else {
        _filteredContacts = _allContacts.where((c) {
          final name = c.displayName.toLowerCase();
          final phone = c.phoneNumber.toLowerCase();
          return name.contains(query) || phone.contains(query);
        }).toList();
      }
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedUserIds.length == _allContacts.length) {
        _selectedUserIds.clear();
      } else {
        _selectedUserIds = _allContacts.map((c) => c.id).toSet();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isExclude = widget.mode == ContactPickerMode.exclude;
    final title = isExclude ? 'Hide status from...' : 'Only share status with...';
    final accentColor = isExclude ? Colors.redAccent : context.colors.primary;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: context.colors.scaffoldBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: context.colors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.colors.textPrimary,
                ),
              ),
              Text(
                isExclude
                    ? '${_selectedUserIds.length} contacts excluded'
                    : '${_selectedUserIds.length} contacts selected',
                style: TextStyle(
                  fontSize: 12,
                  color: context.colors.textSecondary,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(
                _selectedUserIds.length == _allContacts.length
                    ? Icons.deselect
                    : Icons.select_all,
                color: context.colors.primary,
              ),
              tooltip: _selectedUserIds.length == _allContacts.length ? 'Deselect All' : 'Select All',
              onPressed: _allContacts.isNotEmpty ? _toggleSelectAll : null,
            ),
          ],
        ),
        body: Column(
          children: [
            // Search field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: context.colors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search contacts...',
                  hintStyle: TextStyle(color: context.colors.textHint),
                  prefixIcon: Icon(Icons.search, color: context.colors.textHint),
                  filled: true,
                  fillColor: context.colors.lightBackground,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const Divider(height: 1),

            // Contact list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredContacts.isEmpty
                      ? Center(
                          child: Text(
                            'No contacts found',
                            style: TextStyle(color: context.colors.textHint),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredContacts.length,
                          itemBuilder: (ctx, index) {
                            final contact = _filteredContacts[index];
                            final isSelected = _selectedUserIds.contains(contact.id);
                            final name = contact.displayName;

                            return CheckboxListTile(
                              value: isSelected,
                              activeColor: accentColor,
                              checkColor: Colors.white,
                              onChanged: (bool? checked) {
                                setState(() {
                                  if (checked == true) {
                                    _selectedUserIds.add(contact.id);
                                  } else {
                                    _selectedUserIds.remove(contact.id);
                                  }
                                });
                              },
                              secondary: CircleAvatar(
                                radius: 20,
                                backgroundColor: context.colors.primary.withValues(alpha: 0.15),
                                backgroundImage: contact.profilePictureUrl != null &&
                                        contact.profilePictureUrl!.isNotEmpty
                                    ? NetworkImage(contact.profilePictureUrl!)
                                    : null,
                                child: contact.profilePictureUrl == null ||
                                        contact.profilePictureUrl!.isEmpty
                                    ? Text(
                                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: context.colors.primary,
                                        ),
                                      )
                                    : null,
                              ),
                              title: Text(
                                name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: context.colors.textPrimary,
                                ),
                              ),
                              subtitle: Text(
                                contact.phoneNumber,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: context.colors.textSecondary,
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),

        floatingActionButton: FloatingActionButton(
          backgroundColor: context.colors.primary,
          elevation: 4,
          onPressed: () => Navigator.pop(context, _selectedUserIds.toList()),
          child: const Icon(Icons.check, color: Colors.white),
        ),
      ),
    );
  }
}
