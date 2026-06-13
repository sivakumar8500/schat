abstract class ContactsEvent {
  const ContactsEvent();
}

class LoadContacts extends ContactsEvent {
  const LoadContacts();
}

class SyncContactsEvent extends ContactsEvent {
  const SyncContactsEvent();
}
