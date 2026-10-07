import 'dart:async';
import 'dart:developer';
import 'package:fast_contacts/fast_contacts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:injectable/injectable.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:schat/core/network/api_result.dart';
import 'package:schat/core/storage/storage_service.dart';
import 'package:schat/features/dashboard_screen/src/domain/models/chat_model.dart';
import 'package:schat/features/dashboard_screen/src/domain/repositories/contacts_repository.dart';
import 'package:schat/features/dashboard_screen/src/domain/repositories/dashboard_repository.dart';
import 'package:schat/features/profile_screen/src/domain/models/user_model.dart';
import 'package:schat/features/chat_socket_screen/src/domain/chat_socket_repository.dart';
import 'package:schat/injection.dart';
import 'contacts_event.dart';
import 'contacts_state.dart';

@lazySingleton
class ContactsBloc extends Bloc<ContactsEvent, ContactsState> {
  final ContactsRepository _contactsRepository;
  final ChatSocketRepository _socketRepository;
  final StorageService _storageService;
  final DashboardRepository _dashboardRepository;
  // ignore: unused_field
  StreamSubscription? _socketSubscription;

  ContactsBloc(
    this._contactsRepository,
    this._socketRepository,
    this._storageService, [
    DashboardRepository? dashboardRepository,
  ])  : _dashboardRepository = dashboardRepository ?? getIt<DashboardRepository>(),
        super(const ContactsInitial()) {
    on<LoadContacts>(_onLoadContacts);
    on<SyncContactsEvent>(_onSyncContacts);
    on<DiscoverContactsEvent>(_onDiscoverContacts);
    on<RemoveContact>(_onRemoveContact);
    on<UpdateContactStatus>(_onUpdateContactStatus);

    _listenToSocket();
  }

  Map<String, dynamic> _cleanMap(Map<dynamic, dynamic> map) {
    final Map<String, dynamic> result = {};
    map.forEach((key, val) {
      final k = key.toString();
      if (val is Map) {
        result[k] = _cleanMap(val);
      } else if (val is List) {
        result[k] = val.map((item) => item is Map ? _cleanMap(item) : item).toList();
      } else {
        result[k] = val;
      }
    });
    return result;
  }

  void _listenToSocket() {
    _socketSubscription = _socketRepository.onMessage.listen((data) {
      if (data is Map) {
        final cleanData = _cleanMap(data);
        final type = cleanData['type']?.toString();
        if (type == 'user_status' || type == 'user_online' || type == 'user_offline') {
          final userId = (cleanData['user_id'] ?? cleanData['id'] ?? cleanData['sender_id'])
              ?.toString();
          final status = cleanData['status']?.toString();
          final isOnline = type == 'user_online' || (type == 'user_status' && status == 'online');
          final lastSeen = cleanData['last_seen']?.toString();
          if (userId != null) {
            add(
              UpdateContactStatus(
                userId: userId,
                isOnline: isOnline,
                lastSeen: lastSeen,
              ),
            );
          }
        }
      }
    });
  }

  List<UserModel> _sortUsers(List<UserModel> users) {
    final list = List<UserModel>.from(users);
    list.sort((a, b) => a.displayName.trim().toLowerCase().compareTo(b.displayName.trim().toLowerCase()));
    return list;
  }

  List<Contact> _sortContacts(List<Contact> contacts) {
    final list = List<Contact>.from(contacts);
    list.sort((a, b) => a.displayName.trim().toLowerCase().compareTo(b.displayName.trim().toLowerCase()));
    return list;
  }

  String _normalizePhone(String phone) {
    String normalized = phone.replaceAll(RegExp(r'\D'), '');
    if (normalized.length > 10) {
      normalized = normalized.substring(normalized.length - 10);
    }
    return normalized;
  }

  Future<List<UserModel>> _filterAllowedUsers(
    List<UserModel> serverUsers,
    List<Contact> deviceContacts,
    List<String> hiddenPhoneNumbers,
  ) async {
    final devicePhones = <String>{};
    for (final c in deviceContacts) {
      for (final p in c.phones) {
        final norm = _normalizePhone(p.number);
        if (norm.isNotEmpty) {
          devicePhones.add(norm);
        }
      }
    }

    final activeChatUserIds = <String>{};
    final activeChatPhones = <String>{};
    final List<UserModel> activeChatUsersToAdd = [];

    try {
      final chatsResult = await _dashboardRepository.getChats();
      if (chatsResult is Success<List<ChatModel>>) {
        for (final chat in chatsResult.data) {
          // Include users where an active chat with message history exists
          if (!chat.isGroup && chat.lastMessage != null && chat.recipient.id.isNotEmpty) {
            activeChatUserIds.add(chat.recipient.id);
            final norm = _normalizePhone(chat.recipient.phoneNumber);
            if (norm.isNotEmpty) {
              activeChatPhones.add(norm);
            }

            activeChatUsersToAdd.add(
              UserModel(
                id: chat.recipient.id,
                phoneNumber: chat.recipient.phoneNumber,
                username: chat.recipient.username,
                contactName: chat.recipient.contactName,
                firstName: chat.recipient.firstName,
                lastName: chat.recipient.lastName,
                profilePictureUrl: chat.recipient.profilePictureUrl,
                isOnline: chat.recipient.isOnline,
                lastSeen: chat.recipient.lastSeen,
              ),
            );
          }
        }
      }
    } catch (e) {
      log('Error fetching active chats for allowed user filter: $e');
    }

    final hiddenSet = hiddenPhoneNumbers.toSet();
    final allowedMap = <String, UserModel>{};

    // Add users from server list that match device contacts or active chats
    for (final user in serverUsers) {
      if (hiddenSet.contains(user.phoneNumber)) continue;
      final norm = _normalizePhone(user.phoneNumber);
      final isInContacts = norm.isNotEmpty && devicePhones.contains(norm);
      final hasActiveChat = (user.id.isNotEmpty && activeChatUserIds.contains(user.id)) ||
                            (norm.isNotEmpty && activeChatPhones.contains(norm));

      if (isInContacts || hasActiveChat) {
        allowedMap[user.id.isNotEmpty ? user.id : user.phoneNumber] = user;
      }
    }

    // Also include active chat participants who sent messages
    for (final user in activeChatUsersToAdd) {
      if (hiddenSet.contains(user.phoneNumber)) continue;
      final key = user.id.isNotEmpty ? user.id : user.phoneNumber;
      if (!allowedMap.containsKey(key)) {
        allowedMap[key] = user;
      }
    }

    return allowedMap.values.toList();
  }

  void _onUpdateContactStatus(
    UpdateContactStatus event,
    Emitter<ContactsState> emit,
  ) {
    final currentState = state;
    if (currentState is ContactsLoaded) {
      final updatedSynced = currentState.syncedContacts.map((user) {
        if (user.id == event.userId) {
          return user.copyWith(
            isOnline: event.isOnline,
            lastSeen: event.lastSeen ?? user.lastSeen,
          );
        }
        return user;
      }).toList();

      emit(
        ContactsLoaded(
          contacts: _sortContacts(currentState.contacts),
          syncedContacts: _sortUsers(updatedSynced),
          hiddenPhoneNumbers: currentState.hiddenPhoneNumbers,
        ),
      );
    }
  }

  Future<void> _onRemoveContact(
    RemoveContact event,
    Emitter<ContactsState> emit,
  ) async {
    final currentState = state;
    if (currentState is ContactsLoaded) {
      final user = currentState.syncedContacts
          .where((u) => u.id == event.userId)
          .firstOrNull;

      final updatedSynced = currentState.syncedContacts
          .where((u) => u.id != event.userId)
          .toList();

      List<String> updatedHidden = List.from(currentState.hiddenPhoneNumbers);
      if (user != null && !updatedHidden.contains(user.phoneNumber)) {
        updatedHidden.add(user.phoneNumber);
      }

      emit(
        ContactsLoaded(
          contacts: _sortContacts(currentState.contacts),
          syncedContacts: _sortUsers(updatedSynced),
          hiddenPhoneNumbers: updatedHidden,
        ),
      );

      await _contactsRepository.removeContactFromCache(event.userId);
    }
  }

  Future<void> _onDiscoverContacts(
    DiscoverContactsEvent event,
    Emitter<ContactsState> emit,
  ) async {
    try {
      final query = event.query?.trim() ?? '';
      if (query.isEmpty) {
        add(const LoadContacts());
        return;
      }

      final result = await _contactsRepository.discoverUsers(query: query);
      if (result is Success<List<UserModel>>) {
        final hidden = await _contactsRepository.getHiddenPhoneNumbers();
        final filtered = result.data.where((u) => !hidden.contains(u.phoneNumber)).toList();

        List<Contact> existingContacts = [];
        if (state is ContactsLoaded) {
          existingContacts = (state as ContactsLoaded).contacts;
        }

        emit(
          ContactsLoaded(
            contacts: _sortContacts(existingContacts),
            syncedContacts: _sortUsers(filtered),
            hiddenPhoneNumbers: hidden,
          ),
        );
      }
    } catch (e) {
      log('Error in _onDiscoverContacts: $e');
    }
  }

  Future<void> _onLoadContacts(
    LoadContacts event,
    Emitter<ContactsState> emit,
  ) async {
    if (state is! ContactsLoaded) {
      emit(const ContactsLoading());
    }
    try {
      if (kIsWeb) {
        var cachedUsers = await _contactsRepository.getCachedContacts();
        if (cachedUsers.isEmpty) {
          final serverResult = await _contactsRepository.fetchSyncedContacts();
          if (serverResult is Success<List<UserModel>>) {
            cachedUsers = serverResult.data;
          }
        }
        final hidden = await _contactsRepository.getHiddenPhoneNumbers();
        final filtered = await _filterAllowedUsers(cachedUsers, const [], hidden);
        emit(
          ContactsLoaded(
            contacts: const [],
            syncedContacts: _sortUsers(filtered),
            hiddenPhoneNumbers: hidden,
          ),
        );
        return;
      }

      final status = await Permission.contacts.status;

      if (status.isGranted) {
        await _loadAndSync(emit);
      } else {
        var cachedUsers = await _contactsRepository.getCachedContacts();
        final hidden = await _contactsRepository.getHiddenPhoneNumbers();
        final filteredCached = await _filterAllowedUsers(cachedUsers, const [], hidden);

        if (filteredCached.isNotEmpty) {
          emit(
            ContactsLoaded(
              contacts: const [],
              syncedContacts: _sortUsers(filteredCached),
              hiddenPhoneNumbers: hidden,
            ),
          );
        }

        final requestStatus = await Permission.contacts.request();
        if (requestStatus.isGranted) {
          await _loadAndSync(emit);
        } else if (filteredCached.isEmpty) {
          emit(const ContactsPermissionDenied());
        }
      }
    } catch (e) {
      if (state is! ContactsLoaded) {
        emit(ContactsFailure(errorMessage: e.toString()));
      }
    }
  }

  Future<void> _loadAndSync(Emitter<ContactsState> emit) async {
    try {
      final contacts = await _contactsRepository.getContacts();
      var cachedUsers = await _contactsRepository.getCachedContacts();
      final hidden = await _contactsRepository.getHiddenPhoneNumbers();

      if (cachedUsers.isEmpty) {
        final serverResult = await _contactsRepository.fetchSyncedContacts();
        if (serverResult is Success<List<UserModel>>) {
          cachedUsers = serverResult.data;
        }
      }

      var filteredCached = await _filterAllowedUsers(cachedUsers, contacts, hidden);

      emit(
        ContactsLoaded(
          contacts: _sortContacts(contacts),
          syncedContacts: _sortUsers(filteredCached),
          hiddenPhoneNumbers: hidden,
        ),
      );

      final syncData = _extractSyncData(contacts);
      if (syncData.isNotEmpty) {
        final result = await _contactsRepository.syncContacts(syncData);
        if (result is Success<List<UserModel>>) {
          final filteredResult = await _filterAllowedUsers(result.data, contacts, hidden);
          // Cache verified synced contacts
          await _contactsRepository.cacheContacts(filteredResult);
          emit(
            ContactsLoaded(
              contacts: _sortContacts(contacts),
              syncedContacts: _sortUsers(filteredResult),
              hiddenPhoneNumbers: hidden,
            ),
          );
        }
      }
    } catch (e) {
      log('Error in _loadAndSync: $e');
    }
  }

  Future<void> _onSyncContacts(
    SyncContactsEvent event,
    Emitter<ContactsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ContactsLoaded) {
      emit(const ContactsLoading());
    }
    try {
      if (kIsWeb) {
        final serverResult = await _contactsRepository.fetchSyncedContacts();
        final cachedUsers = serverResult is Success<List<UserModel>>
            ? serverResult.data
            : await _contactsRepository.getCachedContacts();
        final hidden = await _contactsRepository.getHiddenPhoneNumbers();
        final filtered = await _filterAllowedUsers(cachedUsers, const [], hidden);
        emit(
          ContactsLoaded(
            contacts: const [],
            syncedContacts: _sortUsers(filtered),
            hiddenPhoneNumbers: hidden,
          ),
        );
        return;
      }

      final status = await Permission.contacts.request();
      if (!status.isGranted) {
        emit(const ContactsPermissionDenied());
        return;
      }

      final contacts = await _contactsRepository.getContacts();
      final syncData = _extractSyncData(contacts);
      final hidden = await _contactsRepository.getHiddenPhoneNumbers();

      await _storageService.setHasSyncedContacts(true);

      if (syncData.isNotEmpty) {
        final result = await _contactsRepository.syncContacts(syncData);

        if (result is Success<List<UserModel>>) {
          final filteredResult = await _filterAllowedUsers(result.data, contacts, hidden);
          await _contactsRepository.cacheContacts(filteredResult);
          emit(
            ContactsLoaded(
              contacts: _sortContacts(contacts),
              syncedContacts: _sortUsers(filteredResult),
              hiddenPhoneNumbers: hidden,
            ),
          );
        } else {
          final failure = result as Failure;
          if (state is! ContactsLoaded) {
            emit(ContactsFailure(errorMessage: failure.message));
          }
          final filteredSynced = (currentState is ContactsLoaded)
              ? await _filterAllowedUsers(currentState.syncedContacts, contacts, hidden)
              : <UserModel>[];
          emit(
            ContactsLoaded(
              contacts: _sortContacts(contacts),
              syncedContacts: _sortUsers(filteredSynced),
              hiddenPhoneNumbers: hidden,
            ),
          );
        }
      } else {
        final filteredSynced = (currentState is ContactsLoaded)
            ? await _filterAllowedUsers(currentState.syncedContacts, contacts, hidden)
            : <UserModel>[];
        emit(
          ContactsLoaded(
            contacts: _sortContacts(contacts),
            syncedContacts: _sortUsers(filteredSynced),
            hiddenPhoneNumbers: hidden,
          ),
        );
      }
    } catch (e) {
      if (state is! ContactsLoaded) {
        emit(ContactsFailure(errorMessage: e.toString()));
      }
    }
  }

  List<Map<String, String>> _extractSyncData(List<Contact> contacts) {
    final List<Map<String, String>> syncData = [];
    final Set<String> addedPhones = {};

    for (var contact in contacts) {
      final displayName = contact.displayName;
      for (var phone in contact.phones) {
        String normalized = _normalizePhone(phone.number);
        if (normalized.length >= 10) {
          if (!addedPhones.contains(normalized)) {
            addedPhones.add(normalized);
            syncData.add({
              'phone_number': normalized,
              'contact_name': displayName,
            });
          }
        }
      }
    }
    return syncData;
  }
}
