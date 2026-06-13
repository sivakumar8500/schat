import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:schat/core/network/api_result.dart';
import 'package:schat/features/dashboard_screen/src/domain/repositories/contacts_repository.dart';
import 'package:schat/features/profile_screen/src/domain/models/user_model.dart';
import 'package:schat/injection.dart';
import 'contacts_event.dart';
import 'contacts_state.dart';

class ContactsBloc extends Bloc<ContactsEvent, ContactsState> {
  final ContactsRepository _contactsRepository;

  ContactsBloc({ContactsRepository? contactsRepository})
      : _contactsRepository = contactsRepository ?? getIt<ContactsRepository>(),
        super(const ContactsInitial()) {
    on<LoadContacts>(_onLoadContacts);
    on<SyncContactsEvent>(_onSyncContacts);
  }

  Future<void> _onLoadContacts(LoadContacts event, Emitter<ContactsState> emit) async {
    emit(const ContactsLoading());
    try {
      // 1. Check permission first
      final status = await Permission.contacts.status;
      
      if (status.isGranted) {
        await _loadAndSync(emit);
      } else {
        // Try to load from cache first even without permission
        final cachedUsers = await _contactsRepository.getCachedContacts();
        if (cachedUsers.isNotEmpty) {
          emit(ContactsLoaded(
            contacts: const [],
            syncedContacts: cachedUsers,
          ));
          // Still request permission in background to refresh if possible
          final requestStatus = await Permission.contacts.request();
          if (requestStatus.isGranted) {
            await _loadAndSync(emit);
          }
        } else {
          // No cache, must request permission
          final requestStatus = await Permission.contacts.request();
          if (requestStatus.isGranted) {
            await _loadAndSync(emit);
          } else if (requestStatus.isPermanentlyDenied) {
            emit(const ContactsPermissionDenied());
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

      // Show cached or current contacts
      emit(ContactsLoaded(
        contacts: contacts,
        syncedContacts: cachedUsers,
      ));

      // Background sync
      final List<String> phoneNumbers = _extractPhoneNumbers(contacts);
      if (phoneNumbers.isNotEmpty) {
        final result = await _contactsRepository.syncContacts(phoneNumbers);
        if (result is Success<List<UserModel>>) {
          emit(ContactsLoaded(
            contacts: contacts,
            syncedContacts: result.data,
          ));
        }
      }
    } catch (e) {
      // Don't fail the whole load if sync fails
    }
  }

  Future<void> _onSyncContacts(SyncContactsEvent event, Emitter<ContactsState> emit) async {
    final currentState = state;
    if (currentState is ContactsLoaded) {
      emit(const ContactsLoading());
      try {
        final status = await Permission.contacts.request();
        if (!status.isGranted) {
          emit(const ContactsPermissionDenied());
          return;
        }

        final contacts = await _contactsRepository.getContacts();
        final List<String> phoneNumbers = _extractPhoneNumbers(contacts);

        if (phoneNumbers.isNotEmpty) {
          final result = await _contactsRepository.syncContacts(phoneNumbers);
          
          if (result is Success<List<UserModel>>) {
            emit(ContactsLoaded(
              contacts: contacts,
              syncedContacts: result.data,
            ));
          } else {
            emit(ContactsLoaded(contacts: contacts, syncedContacts: currentState.syncedContacts));
          }
        } else {
          emit(ContactsLoaded(contacts: contacts, syncedContacts: currentState.syncedContacts));
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
