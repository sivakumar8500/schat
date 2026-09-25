import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schat/features/profile_screen/src/domain/repositories/profile_repository.dart';
import 'package:schat/features/profile_screen/src/presentation/bloc/emergency_contacts_cubit.dart';
import 'package:schat/features/profile_screen/src/presentation/bloc/emergency_contacts_state.dart';
import 'package:schat/features/dashboard_screen/src/presentation/dashboard_page.dart';
import 'package:schat/injection.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_notifications.dart';
import 'package:schat/utils/common_spaces.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

enum EmergencyFilter { all, personal, helplines }

class EmergencyContactsPage extends StatelessWidget {
  const EmergencyContactsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => EmergencyContactsCubit(getIt<ProfileRepository>())..fetchContacts(),
      child: const _EmergencyContactsView(),
    );
  }
}

class _EmergencyContactsView extends StatefulWidget {
  const _EmergencyContactsView();

  @override
  State<_EmergencyContactsView> createState() => _EmergencyContactsViewState();
}

class _EmergencyContactsViewState extends State<_EmergencyContactsView> {
  EmergencyFilter _selectedFilter = EmergencyFilter.all;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text.trim().toLowerCase();
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _callPhone(String rawPhone) async {
    final cleanPhone = rawPhone.replaceAll(RegExp(r'\s+'), '');
    if (cleanPhone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: cleanPhone);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    } catch (e) {
      if (mounted) {
        context.showErrorNotification('Unable to initiate call to $rawPhone: $e');
      }
    }
  }

  void _showAddContactDialog(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: context.colors.cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Text(
            'Add Emergency Contact',
            style: context.titleLarge.copyWith(fontWeight: FontWeight.bold, color: context.colors.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: TextStyle(color: context.colors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Contact Name',
                  labelStyle: TextStyle(color: context.colors.textSecondary),
                  prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFF00873C)),
                  filled: true,
                  fillColor: context.colors.scaffoldBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              CommonSpaces.h16,
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                style: TextStyle(color: context.colors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  labelStyle: TextStyle(color: context.colors.textSecondary),
                  prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF00873C)),
                  filled: true,
                  fillColor: context.colors.scaffoldBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text('Cancel', style: TextStyle(color: context.colors.textHint)),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final phone = phoneController.text.trim();
                if (name.isEmpty || phone.isEmpty) {
                  context.showErrorNotification('Name and Phone are required');
                  return;
                }
                Navigator.pop(dialogCtx);
                context.read<EmergencyContactsCubit>().addContact(name, phone);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00873C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Text('Add Contact', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showEditContactDialog(BuildContext context, String id, String initialName) {
    final nameController = TextEditingController(text: initialName);

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: context.colors.cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Text(
            'Edit Contact',
            style: context.titleLarge.copyWith(fontWeight: FontWeight.bold, color: context.colors.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: TextStyle(color: context.colors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Contact Name',
                  labelStyle: TextStyle(color: context.colors.textSecondary),
                  prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFF00873C)),
                  filled: true,
                  fillColor: context.colors.scaffoldBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text('Cancel', style: TextStyle(color: context.colors.textHint)),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  context.showErrorNotification('Name is required');
                  return;
                }
                Navigator.pop(dialogCtx);
                context.read<EmergencyContactsCubit>().updateContact(id, name);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00873C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteContactDialog(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: context.colors.cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Text(
            'Delete Contact',
            style: context.titleLarge.copyWith(fontWeight: FontWeight.bold, color: context.colors.textPrimary),
          ),
          content: Text(
            'Are you sure you want to remove this emergency contact?',
            style: TextStyle(color: context.colors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text('Cancel', style: TextStyle(color: context.colors.textHint)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogCtx);
                context.read<EmergencyContactsCubit>().deleteContact(id);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.colors.isDark;

    return Scaffold(
      backgroundColor: context.colors.scaffoldBackground,
      body: Stack(
        children: [
          // Home Wave Lines Background matching Home Screen
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: HomeBackgroundWavePainter(isDark: isDark),
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                _buildSearchBar(),
                _buildFilterPills(),
                Expanded(
                  child: BlocConsumer<EmergencyContactsCubit, EmergencyContactsState>(
                    listener: (context, state) {
                      if (state is EmergencyContactsAddSuccess) {
                        context.showInfoNotification('Emergency contact operation successful');
                      } else if (state is EmergencyContactsAddError) {
                        context.showErrorNotification(state.message);
                      } else if (state is EmergencyContactsError) {
                        context.showErrorNotification(state.message);
                      }
                    },
                    builder: (context, state) {
                      if (state is EmergencyContactsLoading) {
                        return const Center(
                          child: CircularProgressIndicator(color: Color(0xFF00873C)),
                        );
                      } else if (state is EmergencyContactsLoaded) {
                        final response = state.response;
                        final allPersonal = response.personalContacts;
                        final allDefault = response.defaultContacts;

                        final filteredPersonal = allPersonal.where((contact) {
                          if (_searchQuery.isEmpty) return true;
                          return contact.contactName.toLowerCase().contains(_searchQuery) ||
                              contact.phoneNumber.toLowerCase().contains(_searchQuery);
                        }).toList();

                        final filteredDefault = allDefault.where((contact) {
                          if (_searchQuery.isEmpty) return true;
                          return contact.name.toLowerCase().contains(_searchQuery) ||
                              contact.phoneNumber.toLowerCase().contains(_searchQuery) ||
                              contact.description.toLowerCase().contains(_searchQuery);
                        }).toList();

                        final showPersonal = _selectedFilter == EmergencyFilter.all ||
                            _selectedFilter == EmergencyFilter.personal;
                        final showDefault = _selectedFilter == EmergencyFilter.all ||
                            _selectedFilter == EmergencyFilter.helplines;

                        if ((!showPersonal || filteredPersonal.isEmpty) &&
                            (!showDefault || filteredDefault.isEmpty)) {
                          return _buildEmptyState(context);
                        }

                        return RefreshIndicator(
                          onRefresh: () async {
                            context.read<EmergencyContactsCubit>().fetchContacts();
                          },
                          color: const Color(0xFF00873C),
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(16, 6, 16, 100),
                            children: [
                              if (showPersonal && filteredPersonal.isNotEmpty) ...[
                                const Padding(
                                  padding: EdgeInsets.only(left: 6, bottom: 8, top: 4),
                                  child: Text(
                                    'Personal Emergency Contacts',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF00873C),
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                                ...filteredPersonal.map((contact) {
                                  final date = contact.createdAtInt != null
                                      ? DateTime.fromMillisecondsSinceEpoch(contact.createdAtInt! * 1000)
                                      : DateTime.now();
                                  final formattedDate = DateFormat('MMM d, yyyy h:mm a').format(date.toLocal());

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    decoration: BoxDecoration(
                                      color: isDark ? context.colors.cardBackground : Colors.white,
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: context.colors.border.withValues(alpha: 0.35),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 24,
                                            backgroundColor: const Color(0xFFE8F5E9),
                                            child: Text(
                                              contact.contactName.isNotEmpty
                                                  ? contact.contactName[0].toUpperCase()
                                                  : '?',
                                              style: const TextStyle(
                                                color: Color(0xFF00873C),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                              ),
                                            ),
                                          ),
                                          CommonSpaces.w12,
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  contact.contactName,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 15,
                                                    color: context.colors.textPrimary,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 3),
                                                Text(
                                                  contact.phoneNumber,
                                                  style: TextStyle(
                                                    color: context.colors.textSecondary,
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  'Added $formattedDate',
                                                  style: TextStyle(
                                                    color: context.colors.textHint,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              // Call Button
                                              Container(
                                                width: 38,
                                                height: 38,
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFE8F5E9),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: IconButton(
                                                  padding: EdgeInsets.zero,
                                                  icon: const Icon(
                                                    Icons.phone_rounded,
                                                    color: Color(0xFF00873C),
                                                    size: 20,
                                                  ),
                                                  tooltip: 'Make Call',
                                                  onPressed: () => _callPhone(contact.phoneNumber),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              // Edit Button
                                              Container(
                                                width: 34,
                                                height: 34,
                                                decoration: BoxDecoration(
                                                  color: context.colors.lightBackground,
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: IconButton(
                                                  padding: EdgeInsets.zero,
                                                  icon: Icon(
                                                    Icons.edit_rounded,
                                                    color: context.colors.textSecondary,
                                                    size: 17,
                                                  ),
                                                  tooltip: 'Edit',
                                                  onPressed: () => _showEditContactDialog(
                                                      context, contact.id, contact.contactName),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              // Delete Button
                                              Container(
                                                width: 34,
                                                height: 34,
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFFFEBEE),
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: IconButton(
                                                  padding: EdgeInsets.zero,
                                                  icon: const Icon(
                                                    Icons.delete_outline_rounded,
                                                    color: Color(0xFFE53935),
                                                    size: 17,
                                                  ),
                                                  tooltip: 'Delete',
                                                  onPressed: () =>
                                                      _showDeleteContactDialog(context, contact.id),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                                const SizedBox(height: 16),
                              ],
                              if (showDefault && filteredDefault.isNotEmpty) ...[
                                const Padding(
                                  padding: EdgeInsets.only(left: 6, bottom: 8, top: 4),
                                  child: Text(
                                    'Default Helplines',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFE53935),
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                                ...filteredDefault.map((contact) {
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    decoration: BoxDecoration(
                                      color: isDark ? context.colors.cardBackground : Colors.white,
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: context.colors.border.withValues(alpha: 0.35),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 24,
                                            backgroundColor: const Color(0xFFFFEBEE),
                                            child: const Icon(
                                              Icons.health_and_safety_rounded,
                                              color: Color(0xFFE53935),
                                              size: 24,
                                            ),
                                          ),
                                          CommonSpaces.w12,
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  contact.name,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 15,
                                                    color: context.colors.textPrimary,
                                                  ),
                                                ),
                                                const SizedBox(height: 3),
                                                Text(
                                                  contact.phoneNumber,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                    color: Color(0xFFE53935),
                                                  ),
                                                ),
                                                if (contact.description.isNotEmpty) ...[
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    contact.description,
                                                    style: TextStyle(
                                                      color: context.colors.textSecondary,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFE8F5E9),
                                              borderRadius: BorderRadius.circular(13),
                                            ),
                                            child: IconButton(
                                              padding: EdgeInsets.zero,
                                              icon: const Icon(
                                                Icons.phone_rounded,
                                                color: Color(0xFF00873C),
                                                size: 20,
                                              ),
                                              tooltip: 'Make Call',
                                              onPressed: () => _callPhone(contact.phoneNumber),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ],
                          ),
                        );
                      }
                      return const Center(
                        child: CircularProgressIndicator(color: Color(0xFF00873C)),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddContactDialog(context),
        backgroundColor: const Color(0xFF00873C),
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, size: 22),
        label: const Text(
          'Add Contact',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.colors.lightBackground,
              border: Border.all(
                color: context.colors.border.withValues(alpha: 0.3),
              ),
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: context.colors.textPrimary, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          CommonSpaces.w12,
          Text(
            'Emergency Contacts',
            style: context.h2.copyWith(
              fontWeight: FontWeight.bold,
              color: context.colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: context.colors.border.withValues(alpha: 0.4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          style: TextStyle(color: context.colors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Search emergency contacts...',
            hintStyle: TextStyle(color: context.colors.textHint, fontSize: 14),
            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF00873C), size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: context.colors.textHint, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterPills() {
    final filters = [
      (EmergencyFilter.all, 'All'),
      (EmergencyFilter.personal, 'Personal'),
      (EmergencyFilter.helplines, 'Helplines'),
    ];

    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (filter, label) = filters[index];
          final isSelected = _selectedFilter == filter;

          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF00873C)
                    : context.colors.cardBackground.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF00873C)
                      : context.colors.border.withValues(alpha: 0.4),
                  width: 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF00873C).withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : context.colors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.health_and_safety_rounded,
                size: 42,
                color: Color(0xFF00873C),
              ),
            ),
            CommonSpaces.h20,
            Text(
              'No Emergency Contacts',
              style: context.titleLarge.copyWith(fontWeight: FontWeight.bold),
            ),
            CommonSpaces.h8,
            Text(
              'Add trusted personal contacts for one-tap emergency calling and safety alerts.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.colors.textSecondary, fontSize: 14, height: 1.4),
            ),
            CommonSpaces.h24,
            ElevatedButton.icon(
              onPressed: () => _showAddContactDialog(context),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Add Contact Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00873C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
