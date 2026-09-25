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
  final String? lastSeen;
  const UpdateContactStatus({
    required this.userId,
    required this.isOnline,
    this.lastSeen,
  });
}

class DiscoverContactsEvent extends ContactsEvent {
  final String? query;
  const DiscoverContactsEvent({this.query});
}
