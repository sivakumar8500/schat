import 'package:fast_contacts/fast_contacts.dart';
import 'package:injectable/injectable.dart';

abstract class ContactsRepository {
  Future<List<Contact>> getContacts();
}

@LazySingleton(as: ContactsRepository)
class ContactsRepositoryImpl implements ContactsRepository {
  @override
  Future<List<Contact>> getContacts() async {
    try {
      return await FastContacts.getAllContacts();
    } catch (e) {
      return [];
    }
  }
}
