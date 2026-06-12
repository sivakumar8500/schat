import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:schat/features/dashboard_screen/src/domain/repositories/contacts_repository.dart';
import 'package:schat/injection.dart';
import 'contacts_event.dart';
import 'contacts_state.dart';

class ContactsBloc extends Bloc<ContactsEvent, ContactsState> {
  final ContactsRepository _contactsRepository;

  ContactsBloc({ContactsRepository? contactsRepository})
      : _contactsRepository = contactsRepository ?? getIt<ContactsRepository>(),
        super(ContactsInitial()) {
    on<LoadContacts>(_onLoadContacts);
  }

  Future<void> _onLoadContacts(LoadContacts event, Emitter<ContactsState> emit) async {
    emit(ContactsLoading());
    try {
      final status = await Permission.contacts.request();
      if (status.isGranted) {
        final contacts = await _contactsRepository.getContacts();
        emit(ContactsLoaded(contacts: contacts));
      } else if (status.isPermanentlyDenied) {
        emit(ContactsPermissionDenied());
      } else {
        emit(ContactsPermissionDenied());
      }
    } catch (e) {
      emit(ContactsFailure(errorMessage: e.toString()));
    }
  }
}
