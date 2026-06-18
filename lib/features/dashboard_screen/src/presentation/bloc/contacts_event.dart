abstract class ContactsEvent {
  const ContactsEvent();
}

class LoadContacts extends ContactsEvent {
  const LoadContacts();
}

class SyncContactsEvent extends ContactsEvent {
  const SyncContactsEvent();
}

class RemoveContact extends ContactsEvent {
  final String userId;
  const RemoveContact(this.userId);
}

class UpdateContactStatus extends ContactsEvent {
  final String userId;
  final bool isOnline;
  const UpdateContactStatus({required this.userId, required this.isOnline});
}
