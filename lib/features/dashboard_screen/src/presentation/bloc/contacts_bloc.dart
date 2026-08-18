import 'dart:async';
import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:injectable/injectable.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:schat/core/network/api_result.dart';
import 'package:schat/core/storage/storage_service.dart';
import 'package:schat/features/dashboard_screen/src/domain/repositories/contacts_repository.dart';
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
  StreamSubscription? _socketSubscription;

  ContactsBloc(
    this._contactsRepository,
    this._socketRepository,
    this._storageService,
  ) : super(const ContactsInitial()) {
    on<LoadContacts>(_onLoadContacts);
    on<SyncContactsEvent>(_onSyncContacts);
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
          contacts: currentState.contacts,
          syncedContacts: updatedSynced,
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
          contacts: currentState.contacts,
          syncedContacts: updatedSynced,
          hiddenPhoneNumbers: updatedHidden,
        ),
      );

      await _contactsRepository.removeContactFromCache(event.userId);
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
        final filteredCached = cachedUsers
            .where((u) => !hidden.contains(u.phoneNumber))
            .toList();
        emit(
          ContactsLoaded(
            contacts: const [],
            syncedContacts: filteredCached,
            hiddenPhoneNumbers: hidden,
          ),
        );
        return;
      }

      final status = await Permission.contacts.status;

      if (status.isGranted) {
        await _loadAndSync(emit);
      } else {
        final cachedUsers = await _contactsRepository.getCachedContacts();
        final hidden = await _contactsRepository.getHiddenPhoneNumbers();
        if (cachedUsers.isNotEmpty) {
          emit(
            ContactsLoaded(
              contacts: const [],
              syncedContacts: cachedUsers,
              hiddenPhoneNumbers: hidden,
            ),
          );
          final requestStatus = await Permission.contacts.request();
          if (requestStatus.isGranted) {
            await _loadAndSync(emit);
          }
        } else {
          final requestStatus = await Permission.contacts.request();
          if (requestStatus.isGranted) {
            await _loadAndSync(emit);
          } else {
            emit(const ContactsPermissionDenied());
          }
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
      log("Siva Contacts get $contacts");
      var cachedUsers = await _contactsRepository.getCachedContacts();
      final hidden = await _contactsRepository.getHiddenPhoneNumbers();

      if (cachedUsers.isEmpty) {
        final serverResult = await _contactsRepository.fetchSyncedContacts();
        if (serverResult is Success<List<UserModel>>) {
          cachedUsers = serverResult.data;
        }
      }

      final filteredCached = cachedUsers
          .where((u) => !hidden.contains(u.phoneNumber))
          .toList();

      emit(
        ContactsLoaded(
          contacts: contacts,
          syncedContacts: filteredCached,
          hiddenPhoneNumbers: hidden,
        ),
      );

      if (!_storageService.hasSyncedContacts()) {
        await _storageService.setHasSyncedContacts(true);
        final syncData = _extractSyncData(contacts);
        if (syncData.isNotEmpty) {
          final result = await _contactsRepository.syncContacts(syncData);
          if (result is Success<List<UserModel>>) {
            final filteredResult = result.data
                .where((u) => !hidden.contains(u.phoneNumber))
                .toList();
            emit(
              ContactsLoaded(
                contacts: contacts,
                syncedContacts: filteredResult,
                hiddenPhoneNumbers: hidden,
              ),
            );
          }
        }
      }
    } catch (e) {
      log(e.toString());
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
        final cachedUsers = serverResult is Success<List<UserModel>> ? serverResult.data : await _contactsRepository.getCachedContacts();
        final hidden = await _contactsRepository.getHiddenPhoneNumbers();
        final filteredCached = cachedUsers
            .where((u) => !hidden.contains(u.phoneNumber))
            .toList();
        emit(
          ContactsLoaded(
            contacts: const [],
            syncedContacts: filteredCached,
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
          final filteredResult = result.data
              .where((u) => !hidden.contains(u.phoneNumber))
              .toList();
          emit(
            ContactsLoaded(
              contacts: contacts,
              syncedContacts: filteredResult,
              hiddenPhoneNumbers: hidden,
            ),
          );
        } else {
          final failure = result as Failure;
          if (state is! ContactsLoaded) {
            emit(ContactsFailure(errorMessage: failure.message));
          }
          final filteredSynced = (currentState is ContactsLoaded)
              ? currentState.syncedContacts
                    .where((u) => !hidden.contains(u.phoneNumber))
                    .toList()
              : <UserModel>[];
          emit(
            ContactsLoaded(
              contacts: contacts,
              syncedContacts: filteredSynced,
              hiddenPhoneNumbers: hidden,
            ),
          );
        }
      } else {
        final filteredSynced = (currentState is ContactsLoaded)
            ? currentState.syncedContacts
                  .where((u) => !hidden.contains(u.phoneNumber))
                  .toList()
            : <UserModel>[];
        emit(
          ContactsLoaded(
            contacts: contacts,
            syncedContacts: filteredSynced,
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

  List<String> _extractPhoneNumbers(dynamic contacts) {
    final List<String> phoneNumbers = [];
    if (contacts == null) return phoneNumbers;

    for (var contact in contacts) {
      if (contact.phones == null) continue;
      for (var phone in contact.phones) {
        String normalized = phone.number.replaceAll(RegExp(r'\D'), '');
        if (normalized.length >= 10) {
          if (normalized.length > 10) {
            normalized = normalized.substring(normalized.length - 10);
          }
          if (!phoneNumbers.contains(normalized)) {
            phoneNumbers.add(normalized);
          }
        }
      }
    }
    return phoneNumbers;
  }

  List<Map<String, String>> _extractSyncData(dynamic contacts) {
    final List<Map<String, String>> syncData = [];
    if (contacts == null) return syncData;

    final Set<String> addedPhones = {};

    for (var contact in contacts) {
      if (contact.phones == null) continue;
      final displayName = contact.displayName ?? '';
      for (var phone in contact.phones) {
        String normalized = phone.number.replaceAll(RegExp(r'\D'), '');
        if (normalized.length >= 10) {
          if (normalized.length > 10) {
            normalized = normalized.substring(normalized.length - 10);
          }
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
