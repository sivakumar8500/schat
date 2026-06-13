import 'package:fast_contacts/fast_contacts.dart';
import 'package:schat/features/profile_screen/src/domain/models/user_model.dart';

abstract class ContactsState {
  const ContactsState();
}

class ContactsInitial extends ContactsState {
  const ContactsInitial();
}

class ContactsLoading extends ContactsState {
  const ContactsLoading();
}

class ContactsLoaded extends ContactsState {
  final List<Contact> contacts;
  final List<UserModel> syncedContacts;
  final List<String> hiddenPhoneNumbers;

  const ContactsLoaded({
    required this.contacts,
    this.syncedContacts = const [],
    this.hiddenPhoneNumbers = const [],
  });
}

class ContactsPermissionDenied extends ContactsState {
  const ContactsPermissionDenied();
}

class ContactsFailure extends ContactsState {
  final String errorMessage;

  const ContactsFailure({required this.errorMessage});
}
