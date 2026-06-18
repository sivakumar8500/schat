import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:schat/core/network/api_result.dart';
import 'package:schat/core/storage/storage_service.dart';
import 'package:schat/features/dashboard_screen/src/domain/repositories/contacts_repository.dart';
import 'package:schat/features/profile_screen/src/domain/models/user_model.dart';
import 'package:schat/features/chat_socket_screen/src/domain/chat_socket_repository.dart';
import 'package:schat/injection.dart';
import 'contacts_event.dart';
import 'contacts_state.dart';

class ContactsBloc extends Bloc<ContactsEvent, ContactsState> {
  final ContactsRepository _contactsRepository;
  final ChatSocketRepository _socketRepository;
  final StorageService _storageService;
  StreamSubscription? _socketSubscription;

  ContactsBloc({
    ContactsRepository? contactsRepository,
    ChatSocketRepository? socketRepository,
    StorageService? storageService,
  })  : _contactsRepository = contactsRepository ?? getIt<ContactsRepository>(),
        _socketRepository = socketRepository ?? getIt<ChatSocketRepository>(),
        _storageService = storageService ?? getIt<StorageService>(),
        super(const ContactsInitial()) {
    on<LoadContacts>(_onLoadContacts);
    on<SyncContactsEvent>(_onSyncContacts);
    on<RemoveContact>(_onRemoveContact);
    on<UpdateContactStatus>(_onUpdateContactStatus);

    _listenToSocket();
  }

  void _listenToSocket() {
    _socketSubscription = _socketRepository.onMessage.listen((data) {
      if (data is Map) {
        final type = data['type']?.toString();
        if (type == 'user_status') {
          final userId = (data['user_id'] ?? data['id'] ?? data['sender_id'])?.toString();
          final status = data['status']?.toString();
          if (userId != null) {
            add(UpdateContactStatus(
              userId: userId,
              isOnline: status == 'online',
            ));
          }
        }
      }
    });
  }

  void _onUpdateContactStatus(UpdateContactStatus event, Emitter<ContactsState> emit) {
    final currentState = state;
    if (currentState is ContactsLoaded) {
      final updatedSynced = currentState.syncedContacts.map((user) {
        if (user.id == event.userId) {
          return user.copyWith(isOnline: event.isOnline);
        }
        return user;
      }).toList();
      
      emit(ContactsLoaded(
        contacts: currentState.contacts,
        syncedContacts: updatedSynced,
        hiddenPhoneNumbers: currentState.hiddenPhoneNumbers,
      ));
    }
  }

  Future<void> _onRemoveContact(RemoveContact event, Emitter<ContactsState> emit) async {
    final currentState = state;
    if (currentState is ContactsLoaded) {
      final user = currentState.syncedContacts.where((u) => u.id == event.userId).firstOrNull;
      
      final updatedSynced = currentState.syncedContacts
          .where((u) => u.id != event.userId)
          .toList();
      
      List<String> updatedHidden = List.from(currentState.hiddenPhoneNumbers);
      if (user != null && !updatedHidden.contains(user.phoneNumber)) {
        updatedHidden.add(user.phoneNumber);
      }

      emit(ContactsLoaded(
        contacts: currentState.contacts,
        syncedContacts: updatedSynced,
        hiddenPhoneNumbers: updatedHidden,
      ));
      
      await _contactsRepository.removeContactFromCache(event.userId);
    }
  }

  Future<void> _onLoadContacts(LoadContacts event, Emitter<ContactsState> emit) async {
    emit(const ContactsLoading());
    try {
      final status = await Permission.contacts.status;
      
      if (status.isGranted) {
        await _loadAndSync(emit);
      } else {
        final cachedUsers = await _contactsRepository.getCachedContacts();
        final hidden = await _contactsRepository.getHiddenPhoneNumbers();
        if (cachedUsers.isNotEmpty) {
          emit(ContactsLoaded(
            contacts: const [],
            syncedContacts: cachedUsers,
            hiddenPhoneNumbers: hidden,
          ));
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
      emit(ContactsFailure(errorMessage: e.toString()));
    }
  }

  Future<void> _loadAndSync(Emitter<ContactsState> emit) async {
    try {
      final contacts = await _contactsRepository.getContacts();
      final cachedUsers = await _contactsRepository.getCachedContacts();
      final hidden = await _contactsRepository.getHiddenPhoneNumbers();

      final filteredCached = cachedUsers.where((u) => !hidden.contains(u.phoneNumber)).toList();

      emit(ContactsLoaded(
        contacts: contacts,
        syncedContacts: filteredCached,
        hiddenPhoneNumbers: hidden,
      ));

      if (!_storageService.hasSyncedContacts()) {
        final List<String> phoneNumbers = _extractPhoneNumbers(contacts);
        if (phoneNumbers.isNotEmpty) {
          final result = await _contactsRepository.syncContacts(phoneNumbers);
          if (result is Success<List<UserModel>>) {
            final filteredResult = result.data.where((u) => !hidden.contains(u.phoneNumber)).toList();
            emit(ContactsLoaded(
              contacts: contacts,
              syncedContacts: filteredResult,
              hiddenPhoneNumbers: hidden,
            ));
            await _storageService.setHasSyncedContacts(true);
          }
        }
      }
    } catch (e) {
    }
  }

  Future<void> _onSyncContacts(SyncContactsEvent event, Emitter<ContactsState> emit) async {
    final currentState = state;
    if (currentState is ContactsLoaded || state is ContactsInitial) {
      emit(const ContactsLoading());
      try {
        final status = await Permission.contacts.request();
        if (!status.isGranted) {
          emit(const ContactsPermissionDenied());
          return;
        }

        final contacts = await _contactsRepository.getContacts();
        final List<String> phoneNumbers = _extractPhoneNumbers(contacts);
        final hidden = await _contactsRepository.getHiddenPhoneNumbers();

        if (phoneNumbers.isNotEmpty) {
          final result = await _contactsRepository.syncContacts(phoneNumbers);
          
          if (result is Success<List<UserModel>>) {
            final filteredResult = result.data.where((u) => !hidden.contains(u.phoneNumber)).toList();
            emit(ContactsLoaded(
              contacts: contacts,
              syncedContacts: filteredResult,
              hiddenPhoneNumbers: hidden,
            ));
            await _storageService.setHasSyncedContacts(true);
          } else {
            final failure = result as Failure;
            emit(ContactsFailure(errorMessage: failure.message));
            final filteredSynced = (currentState is ContactsLoaded) 
                ? currentState.syncedContacts.where((u) => !hidden.contains(u.phoneNumber)).toList()
                : <UserModel>[];
            emit(ContactsLoaded(
              contacts: contacts, 
              syncedContacts: filteredSynced,
              hiddenPhoneNumbers: hidden,
            ));
          }
        } else {
          final filteredSynced = (currentState is ContactsLoaded)
              ? currentState.syncedContacts.where((u) => !hidden.contains(u.phoneNumber)).toList()
              : <UserModel>[];
          emit(ContactsLoaded(
            contacts: contacts, 
            syncedContacts: filteredSynced,
            hiddenPhoneNumbers: hidden,
          ));
        }
      } catch (e) {
        emit(ContactsFailure(errorMessage: e.toString()));
      }
    } else {
      add(const LoadContacts());
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
}
