import 'package:schat/features/profile_screen/src/data/models/emergency_contact_response.dart';

abstract class EmergencyContactsState {
  const EmergencyContactsState();
}

class EmergencyContactsInitial extends EmergencyContactsState {
  const EmergencyContactsInitial();
}

class EmergencyContactsLoading extends EmergencyContactsState {
  const EmergencyContactsLoading();
}

class EmergencyContactsLoaded extends EmergencyContactsState {
  final EmergencyContactResponse response;
  const EmergencyContactsLoaded(this.response);
}

class EmergencyContactsError extends EmergencyContactsState {
  final String message;
  const EmergencyContactsError(this.message);
}

class EmergencyContactsAdding extends EmergencyContactsState {
  const EmergencyContactsAdding();
}

class EmergencyContactsAddSuccess extends EmergencyContactsState {
  const EmergencyContactsAddSuccess();
}

class EmergencyContactsAddError extends EmergencyContactsState {
  final String message;
  const EmergencyContactsAddError(this.message);
}
