import 'package:fast_contacts/fast_contacts.dart';

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

  const ContactsLoaded({required this.contacts});
}

class ContactsPermissionDenied extends ContactsState {
  const ContactsPermissionDenied();
}

class ContactsFailure extends ContactsState {
  final String errorMessage;

  const ContactsFailure({required this.errorMessage});
}
